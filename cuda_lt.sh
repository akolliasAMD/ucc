#!/bin/bash
set -e

function replace_extension {
    __filename=$1
    __ext_old=$2
    __ext_new=$3
    echo "$(basename ${__filename} ${__ext_old})${__ext_new}"
}
libtool_file=$1
lo_filepath=$2

o_filepath=$(replace_extension ${lo_filepath} ".lo" ".o")
lo_dir=$(dirname ${o_filepath})
o_filename=$(basename ${o_filepath})

local_pic_dir=".libs/"
local_npic_dir=""
pic_dir="${lo_dir}/${local_pic_dir}"
npic_dir="${lo_dir}/${local_npic_dir}"

pic_filepath="${pic_dir}${o_filename}"
npic_filepath="${npic_dir}${o_filename}"
local_pic_filepath="${local_pic_dir}${o_filename}"
local_npic_filepath="${local_npic_dir}${o_filename}"

mkdir -p $pic_dir

tmpcmd="${@:3}"
if [[ "$tmpcmd" == *"amdclang"* ]]; then
  cmd="${@:3:2} -x hip -target x86_64-unknown-linux-gnu ${@:5} --offload-arch=native ${@:5} -fPIC -O3 -o ${pic_filepath}"
elif [[ "$tmpcmd" == *"hipcc"* ]]; then
  cmd="${@:3} -fPIC -o ${pic_filepath}"
else
  cmd="${@:3} -Xcompiler -fPIC -o ${pic_filepath}"
fi
echo $cmd
$cmd

if [[ "$tmpcmd" == *"amdclang"* ]]; then
  cmd="${@:3:2} -x hip -target x86_64-unknown-linux-gnu ${@:5} --offload-arch=native ${@:5} -O3 -o ${npic_filepath}"
else
  cmd="${@:3} -o ${npic_filepath}"
fi
echo $cmd
$cmd

libtool_version="$(${libtool_file} --version | sed 's/^/#/g')"

echo "# ${lo_filepath} - a libtool object file"    > ${lo_filepath}
echo "# Generated by ${libtool_version}"          >> ${lo_filepath}
echo ""                                           >> ${lo_filepath}
echo "# Please DO NOT delete this file!"          >> ${lo_filepath}
echo "# It is necessary for linking the library." >> ${lo_filepath}
echo ""                                           >> ${lo_filepath}
echo "# Name of the PIC object."                  >> ${lo_filepath}
echo "pic_object=\'${local_pic_filepath}\'"       >> ${lo_filepath}
echo ""                                           >> ${lo_filepath}
echo "# Name of the non-PIC object."              >> ${lo_filepath}
echo "non_pic_object=\'${local_npic_filepath}\'"  >> ${lo_filepath}
