#
# Makefile for misc devices that really don't fit anywhere else.
#
include $(srctree)/drivers/misc/mediatek/Makefile.custom

#define FILTER_PROJECT_DRV
#$(info ---->$(1))
#ifneq ($(wildcard $(srctree)/drivers/misc/mediatek/mach/$(MTK_PLATFORM)/$(ARCH_MTK_PROJECT)/imgsensor/$(1)),)
#custom_drv += $(1)
#endif
#endef

obj-y				+= kd_sensorlist.o

#$(foreach drv,$(subst $\",,$(CONFIG_CUSTOM_KERNEL_IMGSENSOR)),$(eval $(call FILTER_PROJECT_DRV,$(drv))))
#$(info ---->1-$(custom_drv))
#ifneq ($(wildcard $(custom_drv)),)
#custom_kernel_imgsensor := $(addsuffix /, $(shell echo $(custom_drv)))
#obj-y += $(srctree)/drivers/misc/mediatek/mach/$(MTK_PLATFORM)/$(ARCH_MTK_PROJECT)/imgsensor/$(custom_kernel_imgsensor)
#endif
#$(info -->imgsensor drv by platform $(custom_kernel_imgsensor))
