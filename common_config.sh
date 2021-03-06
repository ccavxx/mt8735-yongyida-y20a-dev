#!/bin/bash

#*******************************************************************
. ./build/envsetup.sh
lunch

CUR_PROJECT=`get_build_var MTK_PROJECT`

#**************************************************************************************
#检查kernel-3.10/arch/arm/configs/中配置与ProjectConfig.mk中的MTK_NEW_MOTOR_CODE一致
#只针对y20a项目，y20b不需要处理
proj=`get_build_var MTK_PROJECT | cut -b 1-4`
if [ $proj = "y20a" ]; then
	file1="kernel-3.10/arch/arm/configs/y20a_dev_debug_defconfig"
	file2="kernel-3.10/arch/arm/configs/y20a_dev_defconfig"
	cfg1=`grep CONFIG_MTK_NEW_MOTOR_CODE $file1`
	cfg2=`grep CONFIG_MTK_NEW_MOTOR_CODE $file2`
	
	projectConfigVar=`get_build_var MTK_NEW_MOTOR_CODE`
	notset="# CONFIG_MTK_NEW_MOTOR_CODE is not set"
	setyes="CONFIG_MTK_NEW_MOTOR_CODE=y"
	if [ $projectConfigVar = "yes" ]; then
		#Set CONFIG_MTK_NEW_MOTOR_CODE in driver configs
		sed -i "s/$cfg1/$setyes/" $file1 
		sed -i "s/$cfg2/$setyes/" $file2 
	else
		sed -i "s/$cfg1/$notset/" $file1 
		sed -i "s/$cfg2/$notset/" $file2 
	fi
fi
#**************************************************************************************

#编译后输出目录
OUT=out/target/product/$CUR_PROJECT
#目标设备路径
TARGET_DEVICE_DIR=device/yongyida/$CUR_PROJECT
MTK_COMMON=device/mediatek/common
MTK_PROJECT_PATH=device/mediatek/mt6735
MTK_LOGO_PATH=bootable/bootloader/lk/dev/logo
MTK_BATTER_PATH=bootable/bootloader/lk/dev/logo/

#客制化配置路径
CUSTOMIZATION_PATH=$1
length=${#CUSTOMIZATION_PATH}
lastchar=${CUSTOMIZATION_PATH:length-1:length}
if [[ $lastchar = "/" ]]; then
	CUSTOMIZATION_PATH=${CUSTOMIZATION_PATH:0:length-1}
fi

export CUSTOMIZATION_PATH
export OUT
export TARGET_DEVICE_DIR
export MTK_COMMON
export MTK_PROJECT_PATH
export MTK_LOGO_PATH
export CUR_PROJECT

. yongyida/tools/copyghookfiles.sh

if [ ! -e $CUSTOMIZATION_PATH/product_config.sh ]; then
	echo "输入的配置路径错误"
	exit 1
fi 

#执行客制化配置目录下的 product_config.sh 以确定机器型号
. $CUSTOMIZATION_PATH/product_config.sh

echo "............................"
echo "USER="$USER
echo "TARGET_PRODUCT="$TARGET_PRODUCT
echo "TARGET_BUILD_VARIANT="$TARGET_BUILD_VARIANT
echo "CUSTOMER_PRODUCT="$CUSTOMER_PRODUCT
echo "WIFI_ONLY="$WIFI_ONLY
echo "CUSTOMIZATION_PATH="$CUSTOMIZATION_PATH
echo "CUR_PROJECT="$CUR_PROJECT

echo "............................"
#*******************************************************************



#**************************************************************************************************
#删除一些上一次客制化编译的文件和恢复默认配置

if [ -d lib ]; then
	rm -rf lib/
fi


#删除一些上一次客制化编译的文件
if [ -d $OUT/system ]; then
	rm -rf $OUT/system
fi

if [ -d $OUT/obj/APPS ]; then
	rm -rf $OUT/obj/APPS
fi

if [ -d out/target/common/obj/APPS ]; then
	rm -rf out/target/common/obj/APPS
fi

if [ -d $OUT/obj/BOOTLOADER_OBJ ]; then
	rm -rf $OUT/obj/BOOTLOADER_OBJ
fi

if [ -d out/target/common/obj/JAVA_LIBRARIES ]; then
	rm -rf out/target/common/obj/JAVA_LIBRARIES
fi


#删除设备目标路径（TARGET_DEVICE_DIR）下的overrides.prop 和 product_overrides.prop
if [ -e $TARGET_DEVICE_DIR/product_overrides.prop ]; then
	rm $TARGET_DEVICE_DIR/product_overrides.prop
fi
if [ -e $TARGET_DEVICE_DIR/overrides.prop ]; then
	rm $TARGET_DEVICE_DIR/overrides.prop
fi


#**************************************************************************************************
echo "run r_init.sh..."
. r_init.sh

#**************************************************************************************************
#执行机器型号默认的相关配置
. yongyida/product/product_common_config.sh
#**************************************************************************************************



#**************************************************************************************************
#覆盖device下一些文件配置，编译进固件。

#拷贝 overrides.prop 到设备目标路径，即 device/yongyida/y20a_dev 下，修改build.prop属性。
if [ -e $CUSTOMIZATION_PATH/oem/overrides.prop ]; then
	cp  -rf $CUSTOMIZATION_PATH/oem/overrides.prop $TARGET_DEVICE_DIR/
fi


# 针对客户项目，修改以下几个文件中配置 custom.conf(device/mediatek/common/) ProjectConfig.mk(device/yongyida/y20a_dev/)
if [ -e $CUSTOMIZATION_PATH/oem/modifyconfigs_before_build ]; then
. yongyida/tools/modify_config_before_make.sh $CUSTOMIZATION_PATH/oem/modifyconfigs_before_build
fi



#----------product_common_config.sh中处理----------------------------
#如有特殊配置，拷贝机器型号配置文件anzhen4_mrd7_64_diffconfig，此配置和yongyida/product下对应型的anzhen4_mrd7_64_diffconfig
#共用的配置是一致的，比如摄像头、触摸屏等配置。此处添加不是多此一举，而是为了一些特殊需求另外添加并覆盖。
#比如台电需求中的要求内存容量显示要足量，需要在内核中配置，一般客户不需要的就不用另外添加。
#if [ -e $CUSTOMIZATION_PATH/oem/anzhen4_mrd7_64_diffconfig ]; then
#	cp  -rf $CUSTOMIZATION_PATH/oem/anzhen4_mrd7_64_diffconfig $TARGET_DEVICE_DIR/
#fi
#**************************************************************************************************



#**************************************************************************************************
#拷贝overlays
if [ -d $CUSTOMIZATION_PATH/oem/overlays ]; then
	cp  -rf $CUSTOMIZATION_PATH/oem/overlays/* $TARGET_DEVICE_DIR/overlay/
fi

if [ -e $CUSTOMIZATION_PATH/oem/device.mk ]; then
	cp  -rf $CUSTOMIZATION_PATH/oem/device.mk $MTK_COMMON/
fi


#拷贝第一帧logo:实则为uboot和kernel的两帧logo	qxga-2048*1536, wxga-1280*800, xga-1024*768
ubootimg=_uboot.bmp
kernelimg=_kernel.bmp
lowbatteryimg=_low_battery.bmp
if [ -e $CUSTOMIZATION_PATH/oem/bootlogo.bmp ]; then
	cp -rf $CUSTOMIZATION_PATH/oem/bootlogo.bmp $MTK_LOGO_PATH/$CUR_PROJECT/$CUR_PROJECT$kernelimg
	cp -rf $CUSTOMIZATION_PATH/oem/bootlogo.bmp $MTK_LOGO_PATH/$CUR_PROJECT/$CUR_PROJECT$ubootimg	
	cp -rf $CUSTOMIZATION_PATH/oem/bootlogo.bmp $MTK_LOGO_PATH/$CUR_PROJECT/$CUR_PROJECT$lowbatteryimg
fi


#**************************************************************************************************
#copy YYDRobotVoiceMainService jar包和库文件
if [ -e $CUSTOMIZATION_PATH/oem/Msc.jar ]; then
	cp  -rf $CUSTOMIZATION_PATH/oem/Msc.jar packages/apps/YYDRobotVoiceMainService/$CUR_PROJECT/libs/
fi

if [ -e $CUSTOMIZATION_PATH/oem/libmsc.so ]; then
	cp  -rf $CUSTOMIZATION_PATH/oem/libmsc.so packages/apps/YYDRobotVoiceMainService/$CUR_PROJECT/libs/armeabi/
fi


#**************************************************************************************************
#拷贝要内置到system/app/下的apk的库文件到临时文件lib
#在Makefile执行oem_config.xml时再拷贝到system/lib/下
mkdir -p oemapk/app/
#alias cp='./yongyida/tools/copy_apk_so.sh'
if [ -d $CUSTOMIZATION_PATH/apk/system_apk ]; then
	for filename in `ls $CUSTOMIZATION_PATH/apk/system_apk`
	do		
		echo $filename 
		echo $CUSTOMIZATION_PATH/apk/system_apk/$filename
		#cp $CUSTOMIZATION_PATH/apk/system_apk/$filename $filename "system_apk"
		./yongyida/tools/copy_apk_so.sh $CUSTOMIZATION_PATH/apk/system_apk/$filename $filename "system_apk"
		
	done
fi
#unalias cp

#拷贝要内置到system/priv-app/下的apk的库文件到临时文件lib
#在Makefile执行oem_config.xml时再拷贝到system/lib/下
mkdir oemapk/priv-app/
#alias cp='./yongyida/tools/copy_apk_so.sh'
if [ -d $CUSTOMIZATION_PATH/apk/system_priv_apk ]; then
	for filename in `ls $CUSTOMIZATION_PATH/apk/system_priv_apk`
	do
		#cp $CUSTOMIZATION_PATH/apk/system_priv_apk/$filename $filename "system_priv_apk"
		./yongyida/tools/copy_apk_so.sh $CUSTOMIZATION_PATH/apk/system_priv_apk/$filename $filename "system_priv_apk"
	done
fi
#unalias cp
#**************************************************************************************************

#**************************************************************************************************
#修改版本号

. $CUSTOMIZATION_PATH/changeVersion.sh

#**************************************************************************************************

#**************************************************************************************************
#开始编译

make -j8

#**************************************************************************************************

make otapackage -j16

echo "make otapackage ..."

#**************************************************************************************************

. yongyida/tools/copyimages.sh

#**************************************************************************************************
#还原编译产生的diff
#恢复默认的overlay和checkout device目录
rm -rf $TARGET_DEVICE_DIR/overlay/  
cd device/
git checkout ./
cd ../

cd build/
git checkout ./
cd ../

#checkout 第一帧logo
cd bootable/bootloader/lk/dev/logo/
git checkout ./
cd ../../../../../
#rm -rf $OUT/obj/EXECUTABLES/efilinux-${TARGET_BUILD_VARIANT}_intermediates

#checkout YYDRobotVoiceMainService
cd packages/apps/YYDRobotVoiceMainService/
git checkout ./
cd ../../../

#**************************************************************************************************

#**************************************************************************************************
#删除编译时用到的全局变量
unset CUSTOMER_PRODUCT
unset CUSTOMIZATION_PATH
unset WIFI_ONLY
#**************************************************************************************************
