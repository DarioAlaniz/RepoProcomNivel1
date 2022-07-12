module  addres_count
#(
parameter count = 15
)
(
    input                   clock,
    input                   i_reset,
    input                   i_run_log,
    input                   i_read_log,
    input   [count-1:0]     i_addr_log_to_mem,
    output  [count-1:0]     o_addr,
    output                  o_mem_full
);

reg             mem_full;  
reg [count-1:0] addr;

always@(posedge clock, negedge i_reset)begin
  if(!i_reset)begin
    addr        <= {count{1'b0}};
    mem_full    <= 1'b0;
  end
  else begin
    if(i_run_log)begin                              //ver si impletar el inicio de escritura con un flanco del comando y mandar un dato para solo leer o escribir no los 2 juntos 
        if (!mem_full)begin                         //hasta que no llene la memoria sigue cambiando la direccion
            if(addr == (2**count)-1)begin
                mem_full  <= 1'b1;
                addr      <= {count{1'b0}};
            end
            else begin
                addr      <= addr + 1'b1;          
            end
        end
    end                                           
    else begin
      if(mem_full)begin
        if(i_read_log)begin                       //puede ser por un cambio de flanco
          addr <= i_addr_log_to_mem;              //i_addr_log_to_men viene del micro 
        end 
      end
    end
  end
end

assign o_mem_full   = mem_full;
assign o_addr       = addr;


endmodule 


//i_addr_log_to_men viene desde el micro a la velocidad del micro!!!