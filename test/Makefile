all: nin ams
nin: nin-100 nin-200
ams: ams-100 ams-200

nin-100:
	TARGET_FW=1.0.0 TARGET_FW_NUMERIC=0x1c2 IMPL=nintendo rspec
ams-100:
	TARGET_FW=1.0.0 TARGET_FW_NUMERIC=0x1c2 IMPL=atmosphere rspec

nin-200:
	TARGET_FW=2.0.0 TARGET_FW_NUMERIC=0x10104 IMPL=nintendo rspec
ams-200:
	TARGET_FW=2.0.0 TARGET_FW_NUMERIC=0x10104 IMPL=atmosphere rspec
