
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
public const string AppName = "Disk Indicator";
public const string AppShortName = "indicator-diskman";
public const string AppVersion = "16.10.1";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public class Main : GLib.Object{

	public string APP_CONFIG_FILE = "";
	public string user_login = "";
	public string user_home = "";
	public string app_mode = "";
	public bool first_run = false;

	public string log_dir = "";
	public string log_file = "";
	public AppLock app_lock = null;
	public bool thread_running = false;
	public bool thread_success = false;
	public bool use_custom_tray_icon = false;
	public string custom_tray_icon_path = "";
	
	public Daemon daemon = null;
	public DiskIndicator disk_indicator;
	
	StartupEntry startup_entry;
	
	public static int main (string[] args) {
		
		set_locale();

		Gtk.init(ref args);
		
		LOG_TIMESTAMP = false;
		LOG_DEBUG = true;
		
		//show help and exit
		if (args.length > 1) {
			switch (args[1].down()) {
				case "--help":
				case "-h":
					stdout.printf (Main.help_message ());
					return 0;
			}
		}

		//init TMP
		LOG_ENABLE = false;
		init_tmp(AppShortName);
		LOG_ENABLE = true;

		/*
		 * Note:
		 * init_tmp() will fail if indicator-diskman is run as normal user
		 * logging will be disabled temporarily so that the error is not displayed to user
		 */

		/*
		var map = Device.get_mounted_filesystems_using_mtab();
		foreach(Device pi in map.values){
			log_msg(pi.description_full());
		}
		exit(0);
		*/

		App = new Main(args);

		bool success = App.start_application(args);
		App.exit_app();

		return (success) ? 0 : 1;
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

		//check_admin_access();

		check_dependencies();
		
		//init_logs();

		lock_app();

		init_members();

		load_app_config();

		startup_entry = new StartupEntry(get_user_name(), AppShortName, "startup", 2);
		startup_entry.create("indicator-diskman");
		
		log_debug("Main(): ok");
	}

	public bool start_application(string[] args){
		bool is_success = true;

		log_debug("start_application()");

		switch(app_mode){
			case "backup":
				//is_success = take_snapshot(false, "", null);
				return is_success;

			default:
				log_debug("Creating MainWindow");
				
				var ind = new DiskIndicator();
				//var num = new Indicator_NumLock();

				//start event loop
				Gtk.main();

				return true;
		}
	}

	public void check_admin_access(){
		
		if (!user_is_admin()){
			var msg = _("This application requires admin access to perform some actions.") + "\n";
			msg += _("Please re-run the application as admin.");

			log_error(msg);

			if (app_mode == ""){
				string title = _("Admin Access Required");
				gtk_messagebox(title, msg, null, true);
			}

			exit(0);
		}
	}
	
	public void check_dependencies(){

		log_debug("check_dependencies()");
		
		string[] dependencies = { "rsync","/sbin/blkid","df","mount","umount","fuser","crontab","cp","rm","touch","ln","sync"};
		
		string path;
		string msg = "";
		foreach(string cmd_tool in dependencies){
			path = get_cmd_path (cmd_tool);
			if ((path == null) || (path.length == 0)){
				msg += " * " + cmd_tool + "\n";
			}
		}

		if (msg.length > 0){
			
			msg = _("Commands listed below are not available on this system") + ":\n\n" + msg + "\n";
			msg += _("Please install required packages and try running Disk Manager Indicator again");
			log_error(msg);

			if (app_mode == ""){
				string title = _("Missing Dependencies");
				gtk_messagebox(title, msg, null, true);
			}
			
			exit(0);
		}
	}

	public void lock_app(){
		app_lock = new AppLock("indicator-diskman");
		app_lock.kill_existing_process();
		app_lock.create(app_mode);
	}

	public void init_logs(){

		try {
			string suffix = (app_mode.length == 0) ? "_gui" : "_" + app_mode;
			
			DateTime now = new DateTime.now_local();
			log_dir = "/var/log/indicator-diskman";
			log_file = path_combine(log_dir,
				"%s_%s.log".printf(now.format("%Y-%m-%d_%H-%M-%S"), suffix));

			var file = File.new_for_path (log_dir);
			if (!file.query_exists ()) {
				file.make_directory_with_parents();
			}

			file = File.new_for_path (log_file);
			if (file.query_exists ()) {
				file.delete ();
			}

			dos_log = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
			if ((app_mode == "")||(LOG_DEBUG)){
				log_msg(_("Session log file") + ": %s".printf(log_file));
			}
		}
		catch (Error e) {
			log_error (e.message);
		}

	}

	public void init_members(){
		// user info
		user_login = get_user_name();
		user_home = get_user_home(user_login);
		
		// app config file
		APP_CONFIG_FILE = user_home + "/.config/%s.json".printf(AppShortName);
	}
	
	public void log_sysinfo(){
		log_msg("");
		log_msg(_("Running") + " %s v%s".printf(AppName, AppVersion));
		
		var distro = LinuxDistro.get_dist_info("/");
		log_msg(_("Distribution") + ": " + distro.full_name());
		log_msg("DIST_ID" + ": " + distro.dist_id);
	}

	public void init_daemon(){
		if (daemon == null){
			daemon = new Daemon("indicator-diskman-daemon", true);
			daemon.start_daemon();
		}
	}
	
	// console functions

	public static string help_message (){
		string msg = "\n" + AppName + " v" + AppVersion + " by Tony George (teejeetech@gmail.com)" + "\n";
		return msg;
	}

	// app config

	public void save_app_config(){

		log_debug("load_app_config()");
		
		var config = new Json.Object();

		config.set_string_member("use_custom_tray_icon", use_custom_tray_icon.to_string());
		config.set_string_member("custom_tray_icon_path", custom_tray_icon_path);
		
		/*
		Json.Array arr = new Json.Array();
		foreach(string path in exclude_list_user){
			arr.add_string_element(path);
		}
		config.set_array_member("exclude",arr);
		*/
		
		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try{
			json.to_file(APP_CONFIG_FILE);
		} catch (Error e) {
	        log_error (e.message);
	    }

	    if ((app_mode == "")||(LOG_DEBUG)){
			log_msg(_("App config saved") + ": '%s'".printf(APP_CONFIG_FILE));
		}
	}

	public void load_app_config(){

		log_debug("load_app_config()");
		
		var f = File.new_for_path(APP_CONFIG_FILE);
		if (!f.query_exists()) {
			first_run = true;
			log_debug("first run mode: config file not found");
			return;
		}

		var parser = new Json.Parser();
        try{
			parser.load_from_file(APP_CONFIG_FILE);
		} catch (Error e) {
	        log_error (e.message);
	    }
        var node = parser.get_root();
        var config = node.get_object();


		use_custom_tray_icon = json_get_bool(config,"use_custom_tray_icon", use_custom_tray_icon);
		custom_tray_icon_path = json_get_string(config,"custom_tray_icon_path", custom_tray_icon_path);
		
		/*
		backup_uuid = json_get_string(config,"backup_device_uuid", backup_uuid);
		this.schedule_monthly = json_get_bool(config,"schedule_monthly",schedule_monthly);
		this.count_monthly = json_get_int(config,"count_monthly",count_monthly);

		if (config.has_member ("exclude-apps")){
			var apps = config.get_array_member("exclude-apps");
			foreach (Json.Node jnode in apps.get_elements()) {
				
				string name = jnode.get_string();
				
			}
		}*/

		if ((app_mode == "")||(LOG_DEBUG)){
			log_msg(_("App config loaded") + ": '%s'".printf(APP_CONFIG_FILE));
		}
	}

	// cleanup

	public void clean_logs(){

		log_debug("clean_logs()");
		
		Gee.ArrayList<string> list = new Gee.ArrayList<string>();

		try{
			var dir = File.new_for_path (log_dir);
			var enumerator = dir.enumerate_children ("*", 0);

			var info = enumerator.next_file ();
			string path;

			while (info != null) {
				if (info.get_file_type() == FileType.REGULAR) {
					path = log_dir + "/" + info.get_name();
					if (path != log_file) {
						list.add(path);
					}
				}
				info = enumerator.next_file ();
			}

			CompareDataFunc<string> compare_func = (a, b) => {
				return strcmp(a,b);
			};

			list.sort((owned) compare_func);

			if (list.size > 500){
				for(int k=0; k<100; k++){
					var file = File.new_for_path (list[k]);
					if (file.query_exists()){
						file.delete();
					}
				}
				log_msg(_("Older log files removed"));
			}
		}
		catch(Error e){
			log_error (e.message);
		}
	}

	public void exit_app (){

		log_debug("exit_app()");
		
		if (daemon != null){
			daemon.send_command("exit");
		}

		if (app_lock != null){
			app_lock.remove();
		}

		save_app_config();

		Gtk.main_quit ();
	}
}






