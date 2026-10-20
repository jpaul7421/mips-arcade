package mars.tools;

import mars.Globals;
import mars.mips.hardware.*;
import java.awt.event.KeyEvent;
import java.util.*;

/** Input/display device only. No game state, button hit tests, or game rules. */
public final class ArcadeDevice implements Observer {
    public static final int FB = 0x10008000;
    public static final int KEY_CTRL = 0xffff0000, KEY_DATA = 0xffff0004;
    public static final int CLICK = 0xffff0100, HELD = 0xffff010c;
    public static final int FRAME = 0xffff0110;
    private final Set<Integer> pressed = new HashSet<Integer>();
    private final Runnable onFrame;
    private volatile boolean connected;
    private volatile int[] pixels = new int[4096];

    public ArcadeDevice(Runnable onFrame) { this.onFrame = onFrame; }
    public int[] pixels() { return pixels; } // Immutable snapshot after publication.

    public void connect() {
        synchronized (Globals.memoryAndRegistersLock) {
            try {
                Globals.memory.deleteObserver(this);
                Globals.memory.addObserver(this, KEY_DATA, KEY_DATA);
                Globals.memory.addObserver(this, FRAME, FRAME);
                connected = true;
                resetInput();
                snapshot();
            } catch (AddressErrorException e) { throw new IllegalStateException(e); }
        }
    }
    public void disconnect() {
        synchronized (Globals.memoryAndRegistersLock) {
            resetInput();
            connected = false;
            Globals.memory.deleteObserver(this);
        }
    }
    public void resetInput() {
        synchronized (Globals.memoryAndRegistersLock) {
            pressed.clear();
            if (!connected) return;
            write(HELD,0); write(CLICK,0); write(KEY_CTRL,0);
        }
    }

    /** Preserve the first pending click until the MIPS program acknowledges it. */
    public boolean click(int x, int y) {
        synchronized (Globals.memoryAndRegistersLock) {
            if (!connected || x<0 || x>=64 || y<0 || y>=64 || read(CLICK)!=0)
                return false;
            write(CLICK+4,x); write(CLICK+8,y); write(CLICK,1);
            return true;
        }
    }
    public void press(int keyCode, char keyChar) {
        synchronized (Globals.memoryAndRegistersLock) {
            if (!connected || !pressed.add(keyCode)) return; // suppress OS repeat
            publishHeld();
            int c=command(keyCode,keyChar);
            if(c!=0 && read(KEY_CTRL)==0) {
                write(KEY_DATA,c); write(KEY_CTRL,1);
            }
        }
    }
    public void release(int keyCode) {
        synchronized (Globals.memoryAndRegistersLock) {
            pressed.remove(keyCode);
            if(connected) publishHeld();
        }
    }
    private void publishHeld() {
        int mask=0;
        if(pressed.contains(KeyEvent.VK_W) || pressed.contains(KeyEvent.VK_UP)
                || pressed.contains(KeyEvent.VK_SPACE)) mask|=1;
        if(pressed.contains(KeyEvent.VK_S) || pressed.contains(KeyEvent.VK_DOWN)) mask|=2;
        write(HELD,mask);
    }
    public static int command(int code,char c) {
        if(code==KeyEvent.VK_UP) return 'w';
        if(code==KeyEvent.VK_DOWN) return 's';
        if(code==KeyEvent.VK_SPACE) return ' ';
        return c>=32 && c<=126 ? Character.toLowerCase(c) : 0;
    }
    /** Same square viewport as paintComponent; return null for letterboxing. */
    public static int[] logical(int px,int py,int width,int height) {
        int side=Math.min(width,height);
        if(side<=0) return null;
        int left=(width-side)/2, top=(height-side)/2;
        if(px<left || py<top || px>=left+side || py>=top+side) return null;
        // Invert paintBitmap's integer cell edges, including non-multiple sizes.
        return new int[]{((px-left+1)*64-1)/side,((py-top+1)*64-1)/side};
    }
    public void snapshot() {
        synchronized (Globals.memoryAndRegistersLock) {
            int[] next=new int[4096];
            for(int i=0;i<4096;i++) next[i]=read(FB+4*i)&0xffffff;
            pixels=next;
        }
        if(onFrame!=null) onFrame.run();
    }
    @Override public void update(Observable source,Object event) {
        MemoryAccessNotice n=(MemoryAccessNotice)event;
        if(!connected || !n.accessIsFromMIPS()) return;
        if(n.getAddress()==KEY_DATA && n.getAccessType()==AccessNotice.READ)
            write(KEY_CTRL,0);
        if(n.getAddress()==FRAME && n.getAccessType()==AccessNotice.WRITE) snapshot();
    }
    private static int read(int a) {
        try { return Globals.memory.getWordNoNotify(a); }
        catch(AddressErrorException e) { throw new IllegalStateException(e); }
    }
    private static void write(int a,int v) {
        try { Globals.memory.setRawWord(a,v); }
        catch(AddressErrorException e) { throw new IllegalStateException(e); }
    }
}
