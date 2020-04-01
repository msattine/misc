import uvm_pkg::*;
`include "uvm_macros.svh"

class simple_xactn extends uvm_sequence_item;
	rand bit[3:0] x;
	rand bit[3:0] y;
	function new(string name = "simple_xactn");
		super.new(name);
	endfunction
	`uvm_object_utils_begin(simple_xactn)
		`uvm_field_int(x, UVM_ALL_ON)
		`uvm_field_int(y, UVM_ALL_ON)
	`uvm_object_utils_end
endclass

class simp_ral_reg1 extends uvm_reg;
   `uvm_object_utils( simp_ral_reg1 )

   rand uvm_reg_field xf;
   rand uvm_reg_field yf;

   function new( string name = "simp_ral_reg1" );
      super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
   endfunction: new

   virtual function void build();
      xf = uvm_reg_field::type_id::create( "xf" );
      xf.configure( .parent                 ( this ), 
                        .size                   ( 4    ), 
                        .lsb_pos                ( 0    ), 
                        .access                 ( "RW" ), 
                        .volatile               ( 0    ),
                        .reset                  ( 4'hF ), 
                        .has_reset              ( 1    ), 
                        .is_rand                ( 1    ), 
                        .individually_accessible( 1    ) );

      yf = uvm_reg_field::type_id::create( "yf" );
      yf.configure( .parent                 ( this ), 
                       .size                   ( 4    ), 
                       .lsb_pos                ( 4    ), 
                       .access                 ( "RW" ), 
                       .volatile               ( 0    ),
                       .reset                  ( 4'hF ), 
                       .has_reset              ( 1    ), 
                       .is_rand                ( 1    ), 
                       .individually_accessible( 1    ) );

   endfunction: build
endclass: simp_ral_reg1

class simp_ral_reg2 extends uvm_reg;
   `uvm_object_utils( simp_ral_reg2 )

   rand uvm_reg_field sxf;

   function new( string name = "simp_ral_reg2" );
      super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
   endfunction: new


   virtual function void build();
      sxf = uvm_reg_field::type_id::create( "sxf" );
      sxf.configure( .parent                 ( this ), 
                       .size                   ( 8    ), 
                       .lsb_pos                ( 0    ), 
                       .access                 ( "RW" ), 
                       .volatile               ( 1    ),
                       .reset                  ( 8'h55), 
                       .has_reset              ( 1    ), 
                       .is_rand                ( 1    ), 
                       .individually_accessible( 1    ) );
   endfunction: build
endclass: simp_ral_reg2

class simp_ral_reg_block extends uvm_reg_block;
   `uvm_object_utils( simp_ral_reg_block )

   rand simp_ral_reg1 reg1;
   rand simp_ral_reg2 reg2;
   uvm_reg_map                reg_map;

   function new( string name = "simp_ral_reg_block" );
      super.new( .name( name ), .has_coverage( UVM_NO_COVERAGE ) );
   endfunction: new

   virtual function void build();
      reg1 = simp_ral_reg1::type_id::create( "reg1" );
      reg1.configure( .blk_parent( this ) );
      reg1.build();

      reg2 = simp_ral_reg2::type_id::create( "reg2" );
      reg2.configure( .blk_parent( this ) );
      reg2.build();

      reg_map = create_map( .name( "reg_map" ), .base_addr( 8'h00 ), 
                            .n_bytes( 1 ), .endian( UVM_LITTLE_ENDIAN ) );
      reg_map.add_reg( .rg( reg1 ), .offset( 8'h00 ), .rights( "RW" ) );
      reg_map.add_reg( .rg( reg2  ), .offset( 8'h01 ), .rights( "RW" ) );
      lock_model(); // finalize the address mapping
   endfunction: build

endclass: simp_ral_reg_block   

class simp_ral_reg_adapter extends uvm_reg_adapter;
   `uvm_object_utils( simp_ral_reg_adapter )

   function new( string name = "" );
      super.new( name );
      supports_byte_enable = 0;
      provides_responses   = 0;
   endfunction: new

   virtual function uvm_sequence_item reg2bus( const ref uvm_reg_bus_op rw );
      simple_xactn simp_tx 
        = simple_xactn::type_id::create("simp_tx");

      if ( rw.kind == UVM_READ ) begin // Read transaction
	`uvm_info(get_name(), "In reg2bus with UVM_READ", UVM_LOW);
	simp_tx.x = 2;
	simp_tx.y = 5;
      end
      else begin // Write Transaction
	`uvm_info(get_name(), "In reg2bus with UVM_WRITE", UVM_LOW);
	simp_tx.x = 4;
	simp_tx.y = 9;
      end
      return simp_tx;
   endfunction: reg2bus

   virtual function void bus2reg( uvm_sequence_item bus_item,
                                  ref uvm_reg_bus_op rw );
      simple_xactn simp_tx;

      if ( ! $cast( simp_tx, bus_item ) ) begin
         `uvm_fatal( get_name(),
                     "bus_item is not of the simple_xactn type." )
         return;
      end
      `uvm_info(get_name(), "In bus2reg", UVM_LOW);
      if(simp_tx.x == 3) begin
		rw.addr = 8'h00;
		rw.data = 8'h1C;
      end
      else begin
		rw.addr = 8'h01;
		rw.data = 8'h1B;
      end

   endfunction: bus2reg
endclass: simp_ral_reg_adapter

typedef uvm_reg_predictor#( simple_xactn) simp_ral_reg_predictor;

class simp_ral_reg_sequence extends uvm_reg_sequence;
   `uvm_object_utils( simp_ral_reg_sequence )

   function new( string name = "" );
      super.new( name );
   endfunction: new

   virtual task body();
      simp_ral_reg_block       ral_reg_block;
      bit [3:0] rx;
      bit [3:0] ry;
      uvm_status_e               status;
      uvm_reg_data_t             sv;

      `uvm_info(get_name(), "In the body of reg_sequence", UVM_LOW);
      $cast( ral_reg_block, model ); // This type casting is needed
					// Eventhough 'model' point to extended object (at runtime), it fails at compile time
      rx = 10;
      ry = 7;
      
      write_reg( ral_reg_block.reg1, status, { rx, ry} );
      `uvm_info(get_name(), $sformatf("reset=%x, mirror=%x and des=%x", ral_reg_block.reg1.get_reset(.kind("HARD")), ral_reg_block.reg1.get_mirrored_value(), ral_reg_block.reg1.get()), UVM_LOW);
      read_reg( ral_reg_block.reg2, status, sv );
   endtask: body
     
endclass: simp_ral_reg_sequence

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
			`uvm_info(get_name(), $sformatf("The randomized values are x=0x%0x and y=0x%0x", xactn.x, xactn.y), UVM_LOW);
			seq_item_port.item_done();
			phase.drop_objection(this);
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
		simp_ral_reg_block reg_block;
		int x = 3;
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		if(! uvm_config_db #(simp_ral_reg_block)::get(.cntxt(this), .inst_name(""), .field_name("ral_reg_block"), .value(reg_block))) begin
			`uvm_info(get_name(), "ral_reg_block not found in monitor", UVM_LOW);
		end
		else begin
			`uvm_info(get_name(), "ral_reg_block is found in monitor", UVM_LOW);
		end
		this.print();
		repeat (2) begin
			mon_xactn = simple_xactn::type_id::create(.name("Mon_xactn"), .parent(this));
			mon_xactn.x = x++;
			mon_xactn.y = 4'hE;
			`uvm_info(get_name(), $sformatf("Monitor is sending a=0x%08x, b=0x%08x", mon_xactn.x, mon_xactn.y), UVM_LOW);
			aport.write(mon_xactn);
      			`uvm_info(get_name(), $sformatf("Reg1: reset=%x, mirror=%x and des=%x", reg_block.reg1.get_reset(.kind("HARD")), reg_block.reg1.get_mirrored_value(), reg_block.reg1.get()), UVM_LOW);
      			`uvm_info(get_name(), $sformatf("Reg2: reset=%x, mirror=%x and des=%x", reg_block.reg2.get_reset(.kind("HARD")), reg_block.reg2.get_mirrored_value(), reg_block.reg2.get()), UVM_LOW);
		end
	endtask
endclass

class simple_agent extends uvm_agent;
	string my_name = "Agent";
	simple_driver driver;
	simple_sequencer sequencer;
	simple_monitor mon;
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
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
		driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simple_env extends uvm_env;
	string my_name = "Env";
	simple_agent agent;
	simp_ral_reg_predictor ral_reg_predictor;
   	simp_ral_reg_block    ral_reg_block;
	simp_ral_reg_adapter ral_reg_adapter;
	`uvm_component_utils(simple_env)
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_name(), $sformatf("In build phase of %s", my_name), UVM_LOW);
		agent = simple_agent::type_id::create(.name("Agent"), .parent(this));
      		ral_reg_predictor = simp_ral_reg_predictor::type_id::create( .name( "ral_reg_predictor" ),
                                                                    .parent( this ) );
      		ral_reg_adapter = simp_ral_reg_adapter::type_id::create( .name( "ral_reg_adapter" ),
                                                                    .parent( this ) );
      		ral_reg_block = simp_ral_reg_block::type_id::create( "ral_reg_block" );
      		ral_reg_block.build();
      		uvm_config_db#( simp_ral_reg_block )::set( .cntxt( this ), 
                                                      .inst_name( "Agent.Monitor" ),
                                                      .field_name( "ral_reg_block" ),
                                                      .value( ral_reg_block ) );
	endfunction
	function void connect_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In connect phase of %s", my_name), UVM_LOW);
         	ral_reg_block.reg_map.set_sequencer( .sequencer( agent.sequencer ),
                                                        .adapter( ral_reg_adapter ) );
      		ral_reg_predictor.map     = ral_reg_block.reg_map;
      		ral_reg_predictor.adapter = ral_reg_adapter;
      		agent.mon.aport.connect( ral_reg_predictor.bus_in );
	endfunction
	task run_phase(uvm_phase phase);
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		this.print();
	endtask
endclass

class simp_ral_test extends uvm_test;
	string my_name = "Test";
	simple_env env;
	`uvm_component_utils(simp_ral_test)
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
		simp_ral_reg_sequence seq1;
		this.print();
		`uvm_info(get_name(), $sformatf("In run phase of %s", my_name), UVM_LOW);
		phase.raise_objection(this);
		seq1 = simp_ral_reg_sequence::type_id::create(.name("simp_ral_reg_sequence"), .parent(this));
		seq1.model = env.ral_reg_block;
		seq1.start(env.agent.sequencer);
		phase.drop_objection(this);
	endtask
endclass

module top();
	initial begin
		`uvm_info("TB_TOP", "Launching the test from tb top", UVM_LOW);
		run_test("simp_ral_test");
	end
endmodule
