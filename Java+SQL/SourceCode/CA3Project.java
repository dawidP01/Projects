package oosdca3;
import javax.swing.*;
import java.awt.*;

/**
 * The driver class of the project
 * @author dawid
 */
public class CA3Project {

    /**
     * Starts up the program
     * @param args
     */
    public static void main(String[] args) {
        Login login = new Login();
        login.setDefaultCloseOperation ( JFrame.EXIT_ON_CLOSE );
        login.setSize ( 275, 170 );
        login.setVisible ( true );
        login.setLocation ( 500, 400 );
    }
}
