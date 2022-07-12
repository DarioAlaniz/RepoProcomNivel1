connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Arty 210319A288D7A" && level==0} -index 0
fpga -file D:/dario/fulgor/workspace_tp8/micro_tp8/_ide/bitstream/download.bit
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Arty 210319A288D7A"} -index 0
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Arty 210319A288D7A"} -index 0
dow D:/dario/fulgor/workspace_tp8/micro_tp8/Debug/micro_tp8.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Arty 210319A288D7A"} -index 0
con
