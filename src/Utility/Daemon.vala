/*
 * Daemon.vala
 *
 * Copyright 2015 Tony George <teejeetech@gmail.com>
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

public class Daemon : AsyncTask {

	public string process_name = "";
	public bool admin_mode = false;
	public bool is_ready = false;

	public int status_code = -1;
	public string output_message = "";
	public string error_message = "";

	//private Pid daemon_pid = -1;
	private string session_key = "";
	private bool append_output = false;
	private bool append_error = false;
	
	private static Gee.HashMap<string, Regex> regex_list;
	
	public Daemon(string daemon_process_name, bool run_as_admin) {
		process_name = daemon_process_name;
		admin_mode = run_as_admin;
		init_regular_expressions();
	}

	private static void init_regular_expressions(){
		if (regex_list != null){
			return; // already initialized
		}
		
		regex_list = new Gee.HashMap<string,Regex>();
		
		try {
			regex_list["status"] = new Regex("""STATUS=([0-9\-]+)""");
			regex_list["output"] = new Regex("""STD_OUT:""");
			regex_list["error"] = new Regex("""STD_ERR:""");
			regex_list["wait-key"] = new Regex("""WAITING_FOR_KEY:""");
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	// execution ----------------------------

	public void start_daemon() {
		dir_create(working_dir);

		var sh = process_name;
		script_file = save_bash_script_temp(sh, script_file, true, false, admin_mode);
		begin();
		
		log_msg("Started daemon process");
	}

	protected override void parse_stdout_line(string out_line){
		if ((out_line == null) || (out_line.length == 0)) {
			return;
		}

		//log_debug("received: %s".printf(out_line));
		
		MatchInfo match;
		if (regex_list["status"].match(out_line, 0, out match)) {
			status_code = int.parse(match.fetch(1));
		}
		else if (regex_list["wait-key"].match(out_line, 0, out match)) {
			session_key = random_string(32);
			write_stdin(session_key);
			is_ready = true;
		}
		else if (regex_list["output"].match(out_line, 0, out match)) {
			append_output = true;
			append_error = false;
		}
		else if (regex_list["error"].match(out_line, 0, out match)) {
			append_output = false;
			append_error = true;
		}
		else{
			// append output message lines
			if (append_output){
				output_message += out_line + "\n";
			}

			// append error message lines
			if (append_error){
				error_message += out_line + "\n";
			}
		}
	}
	
	protected override void parse_stderr_line(string err_line){
		stdout.printf(err_line + "\n");
		stdout.flush();
	}

	public int send_command(string line){

		status_code = -1;
		output_message = "";
		error_message = "";
		append_output = false;
		append_error = false;

		string cmd = "%s|%s".printf(session_key, line);
		//log_debug("send_command=%s".printf(cmd));
		write_stdin(cmd);

		while (status_code == -1){
			sleep(200);
			gtk_do_events();
		}

		return status_code;
	}
	
	protected override void finish_task(){
		log_msg("Daemon exited");
	}
}

