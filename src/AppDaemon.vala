
/*
 * Main.vala
 *
 * Copyright 2012 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public Main App;
public const string AppName = "Disk Indicator Daemon";
public const string AppShortName = "indicator-diskman-daemon";
public const string AppVersion = "16.10.1";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public class Main : GLib.Object{

	public string share_folder = "";
	public string app_conf_path = "";
	public string app_mode = "";
	public bool first_run = false;

	public AppLock app_lock = null;

	public static int main (string[] args) {
		
		set_locale();

		//Gtk.init(ref args);
		
		LOG_TIMESTAMP = false;
		LOG_DEBUG = false;
		
		//init TMP
		LOG_ENABLE = false;
		init_tmp(AppShortName);
		LOG_ENABLE = true;

		App = new Main(args);
		App.start_application();
		App.exit_app();

		return 0;
	}

	private static void set_locale(){
		log_debug("setting locale...");
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "indicator-diskman");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
	}

	public Main(string[] args){

		log_debug("Main()");

		//parse_arguments(args);

		check_admin_access();

		check_dependencies();
		
		//init_logs();

		lock_app();

		//init_members();

		start_application();

		log_debug("Main(): ok");
	}

	public void check_admin_access(){
		if (!user_is_admin()){
			log_error("Not running as admin!");
			exit(0);
		}
	}
	
	public void check_dependencies(){

		log_debug("check_dependencies()");
		
		string[] dependencies = { "udisksctl" };
		
		string path;
		string msg = "";
		foreach(string cmd_tool in dependencies){
			path = get_cmd_path (cmd_tool);
			if ((path == null) || (path.length == 0)){
				msg += " " + cmd_tool + "";
			}
		}

		if (msg.length > 0){
			log_error("Missing dependencies!");
			log_error(" * " + msg.strip());
			exit(0);
		}
	}

	public void lock_app(){
		app_lock = new AppLock("indicator-diskman-daemon");
		app_lock.kill_existing_process();
		app_lock.create("");
	}

	public void start_application(){

		string? key_line = "";

		stdout.printf("WAITING_FOR_KEY:\n");
		stdout.flush();

		do {
			key_line = stdin.read_line();
		}
		while ((key_line == null) || (key_line.length == 0));
		
		string session_key = key_line;
		//log_msg("key='%s'".printf(session_key));
		
		while(true){
			string? line = stdin.read_line();
			string[] args = line.split("|");

			if (args[0] != session_key){
				log_error("Invalid session key!");
				exit(1);
			}
			
			switch(args[1]){
			case "luks_unlock":
				luks_unlock(args);
				break;
			case "luks_lock":
				luks_lock(args);
				break;
			case "automount_on":
				set_udev_rule_for_usb_automount(true);
				break;
			case "automount_off":
				set_udev_rule_for_usb_automount(false);
				break;
			//case "open_baobab":
			//	open_baobab(args);
			//	break;
			case "exit":
				exit(0);
				break;
			default:
				log_error("Command not understood");
				break;
			}
		}
	}

	private void luks_unlock(string[] args){
		string device = args[2];
		if (!device.has_prefix("/dev/")){
			stdout.printf("E: unknown device\n");
			stdout.flush();
		}

		string password = args[3];
		
		string mapped_name = "%s_crypt".printf(file_basename(device));

		var cmd = "echo -n -e '%s' | cryptsetup luksOpen -v --key-file - '%s' '%s'\n".printf(
			password, device, mapped_name);

		string std_out, std_err;
		int status = exec_script_sync(cmd, out std_out, out std_err);

		print_output(status, std_out, std_err);
	}

	private void luks_lock(string[] args){
		string device = args[2];
		if (!device.has_prefix("/dev/")){
			stdout.printf("E:unknown device");
			stdout.flush();
		}

		var cmd = "cryptsetup luksClose -v '%s'\n".printf(device);
		log_debug(cmd);

		string std_out, std_err;
		int status = exec_script_sync(cmd, out std_out, out std_err);

		print_output(status, std_out, std_err);
	}

	private void open_baobab(string[] args){
		string path = args[2];
		if (!dir_exists(path)){
			stdout.printf("E:unknown path");
			stdout.flush();
		}

		var cmd = "baobab '%s'\n".printf(path);
		log_debug(cmd);

		string std_out, std_err;
		int status = exec_script_sync(cmd, out std_out, out std_err);

		print_output(status, std_out, std_err);
	}

	private void set_udev_rule_for_usb_automount(bool automount){
		string rules_file = "/etc/udev/rules.d/85-no-automount.rules";
		if (automount){
			file_delete(rules_file);
		}
		else{
			string txt = "";
			txt += "SUBSYSTEMS=\"usb\"\n";
			txt += "DRIVERS=\"usb\"\n";
			txt += "ENV{UDISKS_AUTO}=\"0\"\n";
			file_write(rules_file, txt);
		}
	}
	
	private void print_output(int status, string std_out, string std_err){

		stdout.printf("STATUS=%d\n".printf(status));
		
		if (std_out.length > 0){
			stdout.printf("STD_OUT:\n");
			stdout.printf("%s\n".printf(std_out));
		}
		
		if (std_err.length > 0){
			stdout.printf("STD_ERR:\n");
			stdout.printf("%s\n".printf(std_err));
		}
		
		stdout.flush();
	}
	
	// cleanup

	public void exit_app (){

		log_debug("exit_app()");
		
		if (app_lock != null){
			app_lock.remove();
		}

		//Gtk.main_quit ();
	}

}






