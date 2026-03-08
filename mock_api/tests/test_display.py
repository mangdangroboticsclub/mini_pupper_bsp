import filecmp
import os
import socket
import psutil
from MangDang.mini_pupper.display import Display, BehaviorState


def test_show_state():
    os.system("rm -f /tmp/Display.log")
    disp = Display()
    disp.show_state(BehaviorState.REST)
    assert filecmp.cmp(os.path.join(os.path.dirname(__file__), 'expected_results', 'display_1'),
                       '/tmp/Display.log')


def test_show_state_twice():
    os.system("rm -f /tmp/Display.log")
    disp = Display()
    disp.show_state(BehaviorState.REST)
    disp.show_state(BehaviorState.REST)
    assert filecmp.cmp(os.path.join(os.path.dirname(__file__), 'expected_results', 'display_1'),
                       '/tmp/Display.log')


def test_show_image():
    os.system("rm -f /tmp/Display.log")
    disp = Display()
    disp.show_image("/path/to/image.png")
    assert filecmp.cmp(os.path.join(os.path.dirname(__file__), 'expected_results', 'display_2'),
                       '/tmp/Display.log')


def test_show_ip():
    os.system("rm -f /tmp/Display.log")
    disp = Display()
    disp.show_ip()
    addrs = psutil.net_if_addrs()
    wlan0_ipv4 = next((addr.address for addr in addrs.get('wlan0', []) if addr.family == socket.AF_INET), None)
    eth0_ipv4 = next((addr.address for addr in addrs.get('eth0', []) if addr.family == socket.AF_INET), None)
    if wlan0_ipv4 is not None:
        ip = wlan0_ipv4
        text = "IP: %s" % str(ip)
        with open('/tmp/Display.exp', 'w') as fh:
            fh.write("%s\n" % text)
        assert filecmp.cmp('/tmp/Display.exp', '/tmp/Display.log')
    elif eth0_ipv4 is not None:
        ip = eth0_ipv4
        text = "IP: %s" % str(ip)
        with open('/tmp/Display.exp', 'w') as fh:
            fh.write("%s\n" % text)
        assert filecmp.cmp('/tmp/Display.exp', '/tmp/Display.log')
    else:
        assert filecmp.cmp(os.path.join(os.path.dirname(__file__), 'expected_results', 'display_3'),
                       '/tmp/Display.log')
