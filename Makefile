CCS_COMPILER			= ccsc
CCS_SOURCE				= main.c
CCS_FLAGS				= +FH +Y9 -L -A -E -M -P -J -D
CCS_FLAGS_BEEPIC		= $(CCS_FLAGS) +GBOOTLOADER="true" +GLEDG="PIN_B4" +GLEDR="PIN_B5"
CCS_FLAGS_DIY			= $(CCS_FLAGS) +GLEDG="PIN_B4" +GLEDR="PIN_B4"
ZIP						= zip -r
BUILD_DIR				= build
PAYLOAD_DIR				= PL3
CLEAN_FILES				= *.err *.esym *.cod *.sym *.hex *.zip $(PAYLOAD_DIR)/*_pic_*.h build

SUPPORTED_FIRMWARES_PIC	= 3.41
#3.40 3.21 3.15 3.10 3.01 2.76
FIRMWARES_PIC1			= $(SUPPORTED_FIRMWARES_PIC:2.%=2_%)
FIRMWARES_PIC2			= $(FIRMWARES_PIC1:3.%=3_%)
FIRMWARES_PIC3			= $(foreach fw,$(FIRMWARES_PIC2), \
						  $(fw))

PAYLOADS_PIC	=	default_payload \
					payload_dev \
					payload_no_unauth_syscall \
					payload_dump_elfs

PAYLOADS_PIC_CAPS	=	DEFAULT_PAYLOAD \
						PAYLOAD_DEV \
						PAYLOAD_NO_UNAUTH_SYSCALL \
						PAYLOAD_DUMP_ELFS 

BOOTLOADER_BUILDS	=	DIY \
						BEEPIC 

VERSION = $(shell cd $(PAYLOAD_DIR) && git rev-parse HEAD && cd ..)

B2HTARGET_PIC = $(CURDIR)/tools/bin2header

all:
		#Remove existing builds.
		rm -f -r build

		#Make bin2header.
		$(MAKE) -C tools

		#Make Payload.
		$(MAKE) -C $(PAYLOAD_DIR)

		#Make custom Payloads.
		$(foreach fw_pic, $(FIRMWARES_PIC3), $(foreach pl_pic, $(PAYLOADS_PIC), ($(B2HTARGET_PIC) $(PAYLOAD_DIR)/$(pl_pic)_$(fw_pic).bin $(PAYLOAD_DIR)/$(pl_pic)_pic_$(fw_pic).h $(pl_pic)_$(fw_pic)); ))

		#HEX with HID Bootloader.
		$(foreach fw_pic, $(FIRMWARES_PIC3), $(foreach pl_pic, $(PAYLOADS_PIC), ( echo "HID Bootloader -> Firmware: $(fw_pic) | Payload: $(pl_pic)"; $(CCS_COMPILER) $(CCS_FLAGS_BEEPIC) +GFW$(fw_pic)="true" +GPAYLOAD="$(pl_pic)" +GPAYLOAD_DIR=$(PAYLOAD_DIR) $(CCS_SOURCE)); ))

		#HEX without Bootloader.
		$(foreach fw_pic, $(FIRMWARES_PIC3), $(foreach pl_pic, $(PAYLOADS_PIC), ( echo "No Bootloader -> Firmware: $(fw_pic) | Payload: $(pl_pic)"; $(CCS_COMPILER) $(CCS_FLAGS_DIY) +GFW$(fw_pic)="true" +GPAYLOAD="$(pl_pic)" +GPAYLOAD_DIR=$(PAYLOAD_DIR) $(CCS_SOURCE)); ))

		#Create build structure.
		mkdir $(BUILD_DIR);
		$(foreach bl_pic, $(BOOTLOADER_BUILDS), mkdir $(BUILD_DIR)/$(bl_pic); )
		$(foreach pl_pic, $(PAYLOADS_PIC), $(foreach bl_pic, $(BOOTLOADER_BUILDS), mkdir $(BUILD_DIR)/$(bl_pic)/$(pl_pic); ))

		#Move each payload to its directory.
		$(foreach pl_pic, $(PAYLOADS_PIC_CAPS), $(foreach bl_pic, $(BOOTLOADER_BUILDS), mv *_$(pl_pic)_*_$(bl_pic).hex $(BUILD_DIR)/$(bl_pic)/$(pl_pic); ))

		#Zip all HEX.
		cd $(BUILD_DIR) && $(ZIP) "PSGrooPIC_V2.xx_HEXs.zip" *

clean: 
		#Clean files.
		rm -f -r $(CLEAN_FILES)

		#Remove compilations.
		$(MAKE) -C $(PAYLOAD_DIR)/ clean
		$(MAKE) -C tools/ clean