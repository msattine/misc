import uvm_pkg::*;
`include "uvm_macros.svh"

class simple_xactn extends uvm_sequence_item;
	rand int x;
	rand int y;
	function new(string name = "simple_xactn");
		super.new(name);
	endfunction
	`uvm_object_utils_begin(simple_xactn)
		`uvm_field_int(x, UVM_ALL_ON)
		`uvm_field_int(y, UVM_ALL_ON)
	`uvm_object_utils_end
endclass

class simple_sequence extends uvm_sequence #(simple_xactn);
	real freq;
	`uvm_object_utils(simple_sequence)
	function new(string name = "simple_sequence");
		super.new(name);
	endfunction
	task body();
		repeat(100) begin
			`uvm_do(req)
			freq = $urandom_range(0, 1000) + $urandom_range(0,1000)*0.000999;
			uvm_config_db#(real)::set(.cntxt(null), .inst_name("*"), .field_name("freq"), .value(freq));
		end
	endtask
endclass

class simple_fcov extends uvm_subscriber #(simple_xactn);
	string my_name = "Fcov";
	uvm_analysis_imp #(simple_xactn, simple_fcov) fc_imp_export;
	uvm_tlm_analysis_fifo #(simple_xactn) fc_fifo;
	simple_xactn fc_xactn;
	`uvm_component_utils(simple_fcov)
	function new(string name = "simple_fcov", uvm_component parent);
		super.new(name, parent);
		fc_imp_export = new("fc_imp_export", this);
		fc_fifo = new("fc_fifo", this);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	function void write(simple_xactn t);
		`uvm_info(get_name(), $sformatf("Fcov in write recieved a=0x%08x, b=0x%08x", t.x, t.y), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		forever begin
			fc_fifo.get(fc_xactn);
			`uvm_info(get_name(), $sformatf("Fcov recieved a=0x%08x, b=0x%08x", fc_xactn.x, fc_xactn.y), UVM_LOW);
		end
	endtask
endclass

class simple_scoreboard extends uvm_scoreboard;
	string my_name = "Scoreboard";
	simple_xactn sc_xactn;
	`uvm_component_utils(simple_scoreboard)
	uvm_tlm_analysis_fifo #(simple_xactn) afifo;
	function new(string name = "simple_scoreboard", uvm_component parent);
		super.new(name, parent);
		afifo = new("Afifo", this);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		forever begin
			afifo.get(sc_xactn);
			`uvm_info(get_name(), $sformatf("Scoreboard recieved a=0x%08x, b=0x%08x", sc_xactn.x, sc_xactn.y), UVM_LOW);
		end
	endtask
endclass

class simple_monitor extends uvm_monitor;
	string my_name = "Monitor";
	simple_xactn mon_xactn;
	uvm_analysis_port #(simple_xactn) aport;
	`uvm_component_utils(simple_monitor)
	function new(string name, uvm_component parent);
		super.new(name, parent);
		aport = new("Aport", this);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		repeat (10) begin
			mon_xactn = simple_xactn::type_id::create(.name("Mon_xactn"), .parent(this));
			void'(mon_xactn.randomize());
			`uvm_info(get_name(), $sformatf("Monitor is sending a=0x%08x, b=0x%08x", mon_xactn.x, mon_xactn.y), UVM_LOW);
			aport.write(mon_xactn);
		end
	endtask
endclass

class simple_sequencer extends uvm_sequencer#(simple_xactn);
	string my_name = "Sequencer";
	`uvm_component_utils(simple_sequencer)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simple_driver extends uvm_driver#(simple_xactn);
	string my_name = "Driver";
	simple_xactn xactn;
	`uvm_component_utils(simple_driver)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
	endfunction
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		forever begin
			seq_item_port.get_next_item(xactn);
			phase.raise_objection(this);
			`uvm_info(get_name(), $sformatf("The randomized values are x=0x%08x and y=0x%08x", xactn.x, xactn.y), UVM_LOW);
			seq_item_port.item_done();
			#10;
			phase.drop_objection(this);
		end
	endtask
endclass

class simple_agent extends uvm_agent;
	string my_name = "Agent";
	simple_driver driver;
	simple_sequencer sequencer;
	simple_monitor mon;
	simple_scoreboard scoreboard;
	simple_fcov fcov;
	`uvm_component_utils(simple_agent)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		sequencer = simple_sequencer::type_id::create(.name("Sequencer"), .parent(this));
		driver = simple_driver::type_id::create(.name("Driver"), .parent(this));
		mon = simple_monitor::type_id::create(.name("Monitor"), .parent(this));
		scoreboard = simple_scoreboard::type_id::create(.name("Scoreboard"), .parent(this));
		fcov = simple_fcov::type_id::create(.name("Fcov"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
		driver.seq_item_port.connect(sequencer.seq_item_export);
		mon.aport.connect(scoreboard.afifo.analysis_export);
		mon.aport.connect(fcov.fc_imp_export);
		mon.aport.connect(fcov.fc_fifo.analysis_export);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simple_env extends uvm_env;
	string my_name = "Env";
	simple_agent agent;
	`uvm_component_utils(simple_env)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		agent = simple_agent::type_id::create(.name("Agent"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simple_test extends uvm_test;
	string my_name = "Test";
	simple_env env;
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		env = simple_env::type_id::create(.name("Env"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		simple_sequence seq1;
		this.print();
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		phase.raise_objection(this);
		seq1 = simple_sequence::type_id::create(.name("Simple_sequence"), .parent(this));
		seq1.start(env.agent.sequencer);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

module top();
	reg clk;
	always #5 clk <= ~clk;
	initial begin
	$shm_open("waves.shm");
	$shm_probe("AC", top);
		clk <= 0;
		`uvm_info("TB_TOP", "Launching the test from tb top", UVM_LOW);
		run_test("simple_test");
	end
	real freq;
	always @(posedge clk) begin
		uvm_config_db#(real)::get(.cntxt(null), .inst_name(""), .field_name("freq"), .value(freq));
	end
endmodule
