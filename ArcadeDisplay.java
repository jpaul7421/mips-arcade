package mars.tools;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

/** MARS plug-in: fixed bitmap protocol with mouse and held-key input. */
public class ArcadeDisplay extends AbstractMarsToolAndApplication {
    private ArcadeDevice device;
    private JPanel canvas;

    public ArcadeDisplay() { super("MIPS Arcade Display", "Arcade Display and Input"); }
    @Override public String getName() { return "Arcade Display and Input"; }

    @Override protected JComponent buildMainDisplayArea() {
        device=new ArcadeDevice(new Runnable() {
            public void run() { if(canvas!=null) canvas.repaint(); }
        });
        canvas=new JPanel() {
            @Override protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                paintBitmap(g,device.pixels(),getWidth(),getHeight());
            }
        };
        canvas.setBackground(new Color(0x0c121b));
        canvas.setPreferredSize(new Dimension(512,512));
        canvas.setFocusable(true);
        canvas.setFocusTraversalKeysEnabled(false);
        canvas.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        canvas.addMouseListener(new MouseAdapter() {
            @Override public void mousePressed(MouseEvent e) {
                canvas.requestFocusInWindow();
                if(!SwingUtilities.isLeftMouseButton(e)) return;
                int[] xy=ArcadeDevice.logical(e.getX(),e.getY(),canvas.getWidth(),canvas.getHeight());
                if(xy!=null) device.click(xy[0],xy[1]);
            }
        });
        canvas.addKeyListener(new KeyAdapter() {
            @Override public void keyPressed(KeyEvent e) {
                device.press(e.getKeyCode(),e.getKeyChar()); e.consume();
            }
            @Override public void keyReleased(KeyEvent e) {
                device.release(e.getKeyCode()); e.consume();
            }
        });
        canvas.addFocusListener(new FocusAdapter() {
            @Override public void focusLost(FocusEvent e) { device.resetInput(); }
        });
        JPanel result=new JPanel(new BorderLayout(4,4));
        result.add(new JLabel("Click controls. W / Up / Space: jump. Hold S / Down: duck."),
                   BorderLayout.NORTH);
        result.add(canvas,BorderLayout.CENTER);
        result.add(new JLabel("Connect to MIPS, run games.asm, then click inside this display."),
                   BorderLayout.SOUTH);
        return result;
    }
    /** Render only the MIPS-produced framebuffer; no Java-drawn game UI. */
    public static void paintBitmap(Graphics g,int[] pixels,int width,int height) {
        int side=Math.min(width,height),left=(width-side)/2,top=(height-side)/2;
        for(int y=0;y<64;y++) for(int x=0;x<64;x++) {
            g.setColor(new Color(pixels[y*64+x]));
            int x0=left+x*side/64,y0=top+y*side/64;
            g.fillRect(x0,y0,(x+1)*side/64-x*side/64,(y+1)*side/64-y*side/64);
        }
    }
    @Override protected void addAsObserver() { device.connect(); }
    @Override protected void deleteAsObserver() { device.disconnect(); }
    @Override protected void reset() { device.resetInput(); device.snapshot(); }
    @Override protected void performSpecialClosingDuties() { if(device!=null) device.disconnect(); }
}
