import uvm_pkg::*;
`include "uvm_macros.svh"

//Example showing the usage of factory override by type and by name

class simple_comp extends uvm_component;
	string my_name = "Comp";
	`uvm_component_utils(simple_comp)
	function new(string name, uvm_component parent);
		super.new(name, parent);
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
	endtask
endclass

class simple_comp1 extends simple_comp;
	string my_name = "Comp1";
	`uvm_component_utils(simple_comp1)
	function new(string name, uvm_component parent);
		super.new(name, parent);
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
	endtask
endclass

class simple_test extends uvm_test;
	string my_name = "Test";
	simple_comp compa, compb;
	`uvm_component_utils(simple_test)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		compa = simple_comp::type_id::create(.name("Compa"), .parent(this)); //This will create component of type simple_comp
		if(top.opt == 1)
			factory.set_type_override_by_type(simple_comp::get_type(), simple_comp1::get_type());
		else if(top.opt == 2) 
			factory.set_type_override_by_name("simple_comp", "simple_comp1");
		factory.print();
		compb = simple_comp::type_id::create(.name("Compb"), .parent(this)); //This will create component of type simple_comp1 if override is set, else of type simple_comp
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

module top();
	int opt;
	initial begin
		if(!$value$plusargs("opt=%d", opt)) //opt=1 -> override by type, opt=2 -> override by name
			opt = 0; // No override
		`uvm_info("TB_TOP", $sformatf("Launching the test from tb top with opt = %0d", opt), UVM_LOW);
		run_test("simple_test");
	end
endmodule
