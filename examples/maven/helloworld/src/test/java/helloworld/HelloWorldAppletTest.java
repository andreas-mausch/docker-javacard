package helloworld;

import static org.assertj.core.api.Assertions.*;

import helloworld.HelloWorldApplet;

import java.io.ByteArrayOutputStream;

import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;

import org.junit.jupiter.api.Test;

import com.licel.jcardsim.bouncycastle.util.encoders.Hex;
import com.licel.jcardsim.smartcardio.CardSimulator;
import com.licel.jcardsim.utils.AIDUtil;

import javacard.framework.AID;

public class HelloWorldAppletTest {

    private static CardSimulator simulator;

    @Test
    public void testPing() throws Exception {
        CardSimulator simulator = new CardSimulator();

        // Install applet
        String PACKAGE_AID_HEX = "01020304050607";
        byte[] aid_bytes = Hex.decode(PACKAGE_AID_HEX + "01");

        AID aid = AIDUtil.create(aid_bytes);
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        bos.write(aid_bytes.length);
        bos.write(aid_bytes);

        simulator.installApplet(aid, HelloWorldApplet.class, bos.toByteArray(), (short) 0, (byte) bos.size());
        bos.close();

        simulator.selectApplet(aid);
        CommandAPDU apdu = new CommandAPDU(0x80, 0x00, 0, 0);
        ResponseAPDU result = simulator.transmitCommand(apdu);
        assertThat(result.getSW()).isEqualTo(0x9000);
        assertThat(result.getData()).isEqualTo("Hello".getBytes());
    }
}
