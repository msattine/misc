import uvm_pkg::*;
`include "uvm_macros.svh"

// Usage of virtual sequence and vrtual sequencers:
//	This is useful say if we are going to re-use the blk-level testbenches at system level.
//	By using this we need not touch any components of existing blk level testbenches
// 	In this example we have two blk level testbenches and a syslevel tb is generated using virtual sequence/er

//***************** Blk1 TB that include transaction, one sequence, driver and agent classes ********************//
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
	`uvm_object_utils(simple_sequence)
	function new(string name = "simple_sequence");
		super.new(name);
	endfunction
	task body();
		repeat(10)
			`uvm_do(req)
	endtask
endclass

typedef uvm_sequencer#(simple_xactn) simple_sequencer;

class simple_driver extends uvm_driver#(simple_xactn);
	string my_name = "Driver";
	simple_xactn xactn;
	`uvm_component_utils(simple_driver)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		forever begin
			seq_item_port.get_next_item(xactn);
			phase.raise_objection(this);
			`uvm_info(get_name(), $sformatf("The randomized values are x=0x%08x and y=0x%08x", xactn.x, xactn.y), UVM_LOW);
			seq_item_port.item_done();
			phase.drop_objection(this);
		end
	endtask
endclass

class simple_agent extends uvm_agent;
	string my_name = "Agent";
	simple_driver driver;
	simple_sequencer sequencer;
	`uvm_component_utils(simple_agent)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sequencer = simple_sequencer::type_id::create(.name("Sequencer"), .parent(this));
		driver = simple_driver::type_id::create(.name("Driver"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction
endclass
//***************** Blk1 End ********************//

//***************** Blk2 TB that include transaction, one sequence, driver and agent classes ********************//
class simple_xactn1 extends uvm_sequence_item;
	rand int x;
	rand int y;
	rand int z;
	function new(string name = "simple_xactn1");
		super.new(name);
	endfunction
	`uvm_object_utils_begin(simple_xactn1)
		`uvm_field_int(x, UVM_ALL_ON)
		`uvm_field_int(y, UVM_ALL_ON)
		`uvm_field_int(z, UVM_ALL_ON)
	`uvm_object_utils_end
endclass

class simple_sequence1 extends uvm_sequence #(simple_xactn1);
	`uvm_object_utils(simple_sequence1)
	function new(string name = "simple_sequence1");
		super.new(name);
	endfunction
	task body();
		repeat(10)
			`uvm_do(req)
	endtask
endclass

typedef uvm_sequencer#(simple_xactn1) simple_sequencer1;

class simple_driver1 extends uvm_driver#(simple_xactn1);
	string my_name = "Driver1";
	simple_xactn1 xactn1;
	`uvm_component_utils(simple_driver1)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
		forever begin
			seq_item_port.get_next_item(xactn1);
			phase.raise_objection(this);
			`uvm_info(get_name(), $sformatf("The randomized values are x=0x%08x, y=0x%08x and z=0x%08x", xactn1.x, xactn1.y, xactn1.z), UVM_LOW);
			seq_item_port.item_done();
			phase.drop_objection(this);
		end
	endtask
endclass

class simple_agent1 extends uvm_agent;
	string my_name = "Agent1";
	simple_driver1 driver1;
	simple_sequencer1 sequencer1;
	`uvm_component_utils(simple_agent1)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sequencer1 = simple_sequencer1::type_id::create(.name("Sequencer1"), .parent(this));
		driver1 = simple_driver1::type_id::create(.name("Driver1"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		driver1.seq_item_port.connect(sequencer1.seq_item_export);
	endfunction
endclass
//***************** Blk2 End ********************//

class simple_vseqr extends uvm_sequencer; //Virtual sequencer is not a parametirized class, as it is not directly interacting with driver
						//It is virtual as it is not interacting directly with driver instead implementing references to multiple sequencers
	string my_name = "Simple_vseqr";
	// Declare both the sequencers
	simple_sequencer seqr;
	simple_sequencer1 seqr1;
	`uvm_component_utils(simple_vseqr)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
endclass

class simple_vseq extends uvm_sequence;
	string my_name = "Simple_vseq";
	int option;
	`uvm_object_utils(simple_vseq)
	// To delcare p_sequencer and assign the handle m_sequncer to it (using $cast)
	`uvm_declare_p_sequencer(simple_vseqr)
	// Declare both the sequencers
	simple_sequence seq;
	simple_sequence1 seq1;
	function new(string name = "Simple_vseq");
		super.new(name);
	endfunction
	task body();
		uvm_config_db #(int)::get(.cntxt(null), .inst_name(""), .field_name("opt"), .value(option));
		if(option == 0) begin
			`uvm_info(get_name(), "Launching sequences using uvm_do_on", UVM_LOW);
			fork
				`uvm_do_on(seq, p_sequencer.seqr)
				`uvm_do_on(seq1, p_sequencer.seqr1)
			join
		end
		else begin
			`uvm_info(get_name(), "Launching sequences using star method of sequence", UVM_LOW);
			fork
				seq.start(p_sequencer.seqr, this);
				seq1.start(p_sequencer.seqr1, this);
			join
		end
	endtask
endclass

class simple_env extends uvm_env;
	string my_name = "Env";
	simple_agent agent;
	simple_agent1 agent1;
	simple_vseqr vseqr;
	`uvm_component_utils(simple_env)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent = simple_agent::type_id::create(.name("Agent"), .parent(this));
		agent1 = simple_agent1::type_id::create(.name("Agent1"), .parent(this));
		vseqr = simple_vseqr::type_id::create(.name("Simple_vseqr"), .parent(this));
	endfunction
	function void connect_phase(uvm_phase phase);
		vseqr.seqr = agent.sequencer;
		vseqr.seqr1 = agent1.sequencer1;
	endfunction
endclass

class simp_vseq_test extends uvm_test;
	string my_name = "Test";
	simple_env env;
	int option;
	`uvm_component_utils(simp_vseq_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		env = simple_env::type_id::create(.name("Env"), .parent(this));
	endfunction
	task run_phase(uvm_phase phase);
		simple_vseq vseq;
		uvm_config_db #(int)::get(.cntxt(null), .inst_name(""), .field_name("opt"), .value(option));
		vseq = simple_vseq::type_id::create(.name("Simple_vseq"), .parent(this));
		if(option == 1) begin
			vseq.seq = simple_sequence::type_id::create(.name("Seq"), .parent(this));
			vseq.seq1 = simple_sequence1::type_id::create(.name("Seq1"), .parent(this));
		end
		phase.raise_objection(this);
		vseq.start(env.vseqr);
		phase.drop_objection(this);
	endtask
endclass

module top();
	int opt;
	initial begin
		if(!$value$plusargs("opt=%d", opt))
			opt = 0; 
		`uvm_info("TB_TOP", $sformatf("Launching the test from tb top with opt = %0d", opt), UVM_LOW);
		uvm_config_db #(int)::set(.cntxt(null), .inst_name(""), .field_name("opt"), .value(opt));
		`uvm_info("TB_TOP", "Launching the test from tb top", UVM_LOW);
		run_test("simp_vseq_test");
	end
endmodule
