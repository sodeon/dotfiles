"""
Command line tool to remote control your Panasonic Viera TV.
"""
from __future__ import print_function
import argparse
import code
import shlex
import sys
import socket
import logging
from sys import stderr
import panasonic_viera
from panasonic_viera import Apps, Keys

MSG_TV_SWITCHED_OFF = 'TV is switched off.'


class CommandRunner(object):
    "Runs defined commands."
    def __init__(self):
        self.commands = {}
        self.command('help', self.help)

    def help(self):
        print('Commands:')
        for c in self.commands:
            print('{}'.format(c))
        print('')

    def command(self, name, fn):
        self.commands[name] = fn

    def run(self, line):
        tokens = shlex.split(line, comments=True)
        command, args = tokens[0], tokens[1:]
        if command not in self.commands:
            print('{}: no such command'.format(command), file=stderr)
            return
        result = self.commands[command](*args)
        if result is not None:
            print(result)


class Console(object):
    ps1 = '> '
    ps2 = '. '

    def __init__(self, runner):
        self.runner = runner

    def run(self, fd):
        for line in fd:
            self.runner.run(line)

    def interact(self, locals=None):
        class LambdaConsole(code.InteractiveConsole):
            def runsource(code_console, source, filename=None, symbol=None):
                try:
                    self.runner.run(source)
                except SystemExit:
                    raise
                except:
                    code_console.showtraceback()
                return False

        try:
            import readline; readline
        except ImportError:
            pass

        ps1, ps2 = getattr(sys, 'ps1', None), getattr(sys, 'ps2', None)
        try:
            sys.ps1, sys.ps2 = self.ps1, self.ps2
            LambdaConsole(locals=locals, filename="<demo>").interact(banner='')
        finally:
            sys.ps1, sys.ps2 = ps1, ps2

    def run(self, fd=None):
        if fd is None:
            fd = sys.stdin
        if fd.isatty():
            self.interact()
        else:
            try:
                self.run(fd=fd)
            except Exception as err:
                print(err, file=stderr)
                return 1
        return 0


class RemoteControl(object):
    """A remote control implementation"""

    def __init__(self, remote_control):
        self._remote_control = remote_control

    def get_device_info(self):
        try:
            res = self._remote_control.get_device_info()
            print('{}'.format(res))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def open_webpage(self, url):
        try:
            self._remote_control.open_webpage(url)
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def launch_app(self, app):
        try:
            app = eval('Apps.' + app).value
            self._remote_control.launch_app(app)
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def get_apps(self):
        try:
            res = self._remote_control.get_apps()
            print('{}'.format(res))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def get_vector_info(self):
        try:
            res = self._remote_control.get_vector_info()
            print('{}'.format(res))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def get_input_mode(self):
        try:
            res = self._remote_control.get_input_mode()
            print('{}'.format(res))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def set_input(self, arg):
        try:
            res = self._remote_control.set_input(arg)
            print('Input is currently set to {}'.format(arg))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def get_volume(self):
        try:
            vol = self._remote_control.get_volume()
            print('Volume is currently set to {}'.format(vol))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def set_volume(self, vol):
        try:
            self._remote_control.set_volume(vol)
            print('Successfully set volume to {}'.format(vol))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def get_mute(self):
        try:
            mute = self._remote_control.get_mute()
            if mute:
                print('TV is muted.')
            else:
                print('TV is not muted.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def set_mute(self, mute):
        try:
            mute = bool(mute)
            self._remote_control.set_mute(mute)
            print('Successfully set mute to {}'.format(mute))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def turn_off(self):
        try:
            self._remote_control.turn_off()
            print('Successfully turned TV off.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def turn_on(self):
        try:
            self._remote_control.turn_on()
            print('Successfully turned TV on.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def volume_up(self):
        try:
            self._remote_control.volume_up()
            print('Successfully turned volume up.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def volume_down(self):
        try:
            self._remote_control.volume_down()
            print('Successfully turned volume down.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def mute_volume(self):
        try:
            self._remote_control.mute_volume()
            print('Successfully muted volume.')
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def send_key(self, key):
        try:
            key = eval('Keys.' + key).value
            self._remote_control.send_key(key)
            print('Successfully sent key {}.'.format(key))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

    def send_keycode(self, key):
        try:
            self._remote_control.send_keycode(key)
            print('Successfully sent key {}.'.format(key))
        except (socket.timeout, TimeoutError, OSError):
            print(MSG_TV_SWITCHED_OFF)

def main():
    """ Handle command line execution. """
    parser = argparse.ArgumentParser(prog='panasonic_viera',
                    description='Remote control a Panasonic Viera TV.')
    parser.add_argument('host', metavar='host', type=str,
                    help='Address of the Panasonic Viera TV')
    parser.add_argument('command', metavar='command', type=str, nargs='?',
                    default="",
                    help='Command issued to Panasonic Viera TV')
    parser.add_argument('arg', metavar='arg', type=str, nargs='?',
                    default="",
                    help='Argument to the command')
    parser.add_argument('--port', metavar='port', type=int,
                    default=panasonic_viera.DEFAULT_PORT,
                    help='Port of the Panasonic Viera TV. Defaults to {}.'.format(panasonic_viera.DEFAULT_PORT))
    parser.add_argument('--verbose', dest='verbose', action='store_const',
                    const=True, default=False,
                    help='debug output')
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    remote_control = RemoteControl(panasonic_viera.RemoteControl(args.host, args.port))
    runner = CommandRunner()
    runner.command('get_device_info', remote_control.get_device_info)
    runner.command('open_webpage', remote_control.open_webpage)
    runner.command('launch_app', remote_control.launch_app)
    runner.command('get_apps', remote_control.get_apps)
    runner.command('get_vector_info', remote_control.get_vector_info)
    runner.command('get_input_mode', remote_control.get_input_mode)
    runner.command('set_input', remote_control.set_input)
    runner.command('get_volume', remote_control.get_volume)
    runner.command('set_volume', remote_control.set_volume)
    runner.command('get_mute', remote_control.get_mute)
    runner.command('set_mute', remote_control.set_mute)
    runner.command('turn_off', remote_control.turn_off)
    runner.command('volume_up', remote_control.volume_up)
    runner.command('volume_down', remote_control.volume_down)
    runner.command('mute_volume', remote_control.mute_volume)
    runner.command('turn_off', remote_control.turn_off)
    runner.command('turn_on', remote_control.turn_on)
    runner.command('send_key', remote_control.send_key)
    runner.command('send_keycode', remote_control.send_keycode)
    runner.command('exit', sys.exit)
    if args.command != "":
        return runner.run(args.command + " " + args.arg)
    else:
        return Console(runner).run()

if __name__ == '__main__':
    sys.exit(main())
