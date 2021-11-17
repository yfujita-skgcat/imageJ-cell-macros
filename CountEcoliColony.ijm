
//
// Image Converter Macro for ImageJ
//
//
//

//
// log_level
// 1: debug
// 2: info
// 3: warn
// 4: error
// 5: fatal
//
var log_level = 1;

// for logging
function log_debug(str){
  if( log_level <= 1 ){
    nowstr = logtimestr();
    print(nowstr + ":debug: " + str);
  }
}
function logtimestr(){
  year = 0;
  month = 0;
  dayOfWeek = 0;
  dayOfMonth = 0;
  hour = 0;
  minute = 0;
  second = 0;
  msec = 0;
  getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
  retStr = "" + year + "/" + month + "/" + dayOfMonth + " " + hour + ":" + minute + ":" + second;
  return retStr;
}
function log_info(str){
  if( log_level <= 2){
    nowstr = logtimestr();
    print(nowstr + ":info: " + str);
  }
}
function log_warn(str){
  if( log_level <= 3){
    nowstr = logtimestr();
    print(nowstr + ":warn: " + str);
  }
}
function log_error(str){
  if( log_level <= 4){
    nowstr = logtimestr();
    print(nowstr + ":error: " + str);
  }
}
function log_fatal(str){
  if( log_level <= 5){
    nowstr = logtimestr();
    print(nowstr + ":fatal: " + str);
  }
}
function debug_wait(sec){
  if( log_level <= 1 && sec > 0){
    wait(sec * 1000);
  }
}
function info_wait(sec){
  if( log_level <= 2 && sec > 0){
    wait(sec * 1000);
  }
}

function find_recursive_dir(dir, recursive){
  log_debug("find_recursive_dir(): " + dir);
  list = getFileList(dir);
  //print_array(list, 22);
  if( list.length == 0){
    return newArray(0);
  }
  current_dir_file_list = newArray(0);
  for(i=0; i<list.length; i++){
    if(startsWith(list[i], ".")){
      // .obsolute とかスキップする.
    } else if(endsWith(list[i], "/") ){
      if(recursive){
        current_dir_file_list = merge_array(current_dir_file_list, find_recursive_dir(""+dir+list[i], recursive));
      }
    } else {
      if(endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".TIF") || endsWith(list[i], ".TIFF") ){
        current_dir_file_list = pushArray(current_dir_file_list, "" + dir + list[i]);
      }
    }
  }
  return Array.sort(current_dir_file_list);
}

// push arg to Array
// This function calls newArray() whenever it adds a file.
// It may affect the performance of this macro.
function pushArray(ary, item){
  return_array = newArray(ary.length + 1);
  for(i = 0; i < ary.length; i++){
    //log_debug("pushArray(): pushing arg = " + ary[i]);
    return_array[i] = ary[i];
  }
  log_debug("pushArray(): pushing last arg = " + item);
  return_array[ary.length] = item;
  return return_array;
}

// merge ary1 and ary2
// This function calls newArray() whenever it merge arrays.
// It may affect the performance of this macro.
function merge_array(ary1, ary2){
  return_array = newArray(ary1.length + ary2.length);
  for(i = 0; i < ary1.length; i++){
    log_debug("added ary[" + i + "] = " + ary1[i]);
    return_array[i] = ary1[i];
  }
  for(i = 0; i < ary2.length; i++){
    log_debug("added ary[" + (ary1.length + i) + "] = " + ary2[i]);
    return_array[ary1.length + i] = ary2[i];
  }
  //print_array(return_array, 10);
  return return_array;
}

function print_array(array, position){
  if(array.length == 0){
    //print(array);
    print(position + ": array is 0");
    return;
  }
  print(position + ": array.length = " + array.length);
  for(i=0; i < array.length; i++){
    print(position + ": array[" + i + "] = " + array[i]);
  }
}

//
// Unused...
function compact_array(array){
  array_size = 0;
  for(i = 0; i < array.length; i++){
    print("loop " + i);
    if(array[i] != 0){ // If array[i] has anything.
      array_size ++;
    }
  }
  return_array = newArray(array_size);
  index = 0;
  for(i = 0; i < array.length; i++){
    if(array[i] != 0){
      return_array[index] = array[i];
      index ++;
    }
  }
  return return_array;
}


function parse_param(file){
  if(!File.exists(file)){
    log_debug("file not found: " + file);
    return false;
  }
  filestring = File.openAsString(file);
  rows = split(filestring, "\n");
  scan_condition = newArray(4); // (x nm, y nm, time ms, z nm)
  for(i=0; i < scan_condition.length; i++){
    scan_condition[i] = false;
  }
  for(i=0; i < rows.length; i++){
    log_debug("rows[" + i + "] = " + rows[i]);
    if( matches(rows[i], "[^:]*:[^:]*") ){
      columns = split(rows[i], ":");
      tag = replace(replace(columns[0], "^  *", ""), "  *$", "");
      val = replace(replace(columns[1], "^  *", ""), "  *$", "");
      log_debug("tag = " + tag);
      log_debug("val = " + val);
      if( matches(tag, "^Ch1 height range.*$") ){
        scan_condition[3] = val;
      } else if( matches(tag, "^X scan size.*$") ){
        scan_condition[0] = val;
      } else if( matches(tag, "^Y scan size.*$") ){
        scan_condition[1] = val;
      } else if( matches(tag, "^Frame time.*$") ){
        scan_condition[2] = val;
      }
    }
  }
  return scan_condition;
}

// do convert
// tone[0]: min, tone[1]: max, tone[2]: color
// format: tiff, jpeg, gif, png
function convert(src, dst, format, background, contrast){
  param_file = replace(src, "_1ch_", "_Par_");
  param_file = replace(param_file, "\\.(tiff|TIFF|tif|TIF)", ".txt");

  params = parse_param(param_file);
  for(i=0;i < params.length; i++){
    if(params[i] == false){
      log_debug("params[" + i + "] = false");
      return false;
    }
  }
  for(i=0; i < params.length; i++){
    log_debug("params[" + i + "] = " + params[i]);
  }


  dst = replace(dst, "\\.(tif|TIF|tiff|TIFF)$", "_x" + params[0] + "y" + params[1] + "t" + params[2] + "z" + params[3] + ".tif" );

  id = open_image(src);
  //log_debug("getInfo(image.subtitle) = " + getInfo("image.subtitle"));
  if( background ){
    run("Subtract Background...", "rolling=50");
  }
  if( contrast ){
    run("Enhance Contrast", "saturated=0.35");
  }

  //colorID = getColorID(src);
  //if( matches(colorID, ".*Blue.*" ) ){
  //  run("Blue");
  //}
  //if( matches(colorID, ".*Red.*" ) ){
  //  run("Red");
  //}


  //run("RGB Color");

  // remove last file seperater
  //dst_dir = replace(dst_dir, "[\\/\\\\]$", "");
  if( format == "tiff" ){
    dst = replace(dst, "\\.(tif|TIF|tiff|TIFF)$", "_8bit.tif");
    run("8-bit");
  } else if( format == "jpeg" ){
    dst = replace(dst, "\\.(tif|TIF|tiff|TIFF)$", ".jpg");
  } else if( format == "gif" ){
    dst = replace(dst, "\\.(tif|TIF|tiff|TIFF)$", ".gif");
  } else if( format == "png" ){
    dst = replace(dst, "\\.(tif|TIF|tiff|TIFF)$", ".png");
  } else {
    log_fatal("Enter unexpected code!!");
  }
  log_debug("parent directory: " + File.getParent(dst));
  mkdir_p(File.getParent(dst));

  log_info("convert from " + src);
  log_info("convert to   " + dst);
  //log_debug("ColorID = " + getColorID(src));
  saveAs(format, dst);
  close_image(id);
}

function close_all_images() {
  while(nImages > 0 ){
    log_debug("nImages = " + nImages);
    close();
  }
}

// if include the string match regexp, return color as string.
// Input must be string array, which is "color_id:color_name"
// example.
// regexp = "^NIBA"
// array[0] = "NIBA:green"
// return = green
function getColor(array, regexp){
  for(i=0; i<array.length; i++){
    if(matches(array[i], regexp){
      return replace(array[i], regexp, "");
    }
  }
  return "";
}
// get color from path
function getColorID(path){
  fname = getFileNameWithoutExtension(path);
  instrument = getInstrument(path);
  if( instrument == "CellaView" ){
    // the matching is not exact.
    return replace(fname, "[A-Z][0-9]+--W[0-9]+--P[0-9]+--Z[0-9]+--T[0-9]+--", "" );
  } else if (instrument == "IX" ){
    // the matching is not exact.
    return replace(fname, ".+_w[0-9]+", "");
  } else {
    return "";
  }
}

// return file name without directory and extension.
function getFileNameWithoutExtension(path){
  fname = File.getName(path);
  fname = replace(fname, "\\.[^.]+$", "");
  return fname;
}

// return capture instrument, IX or cellaview. This function distinguishes
// the instrument by the file name.
function getInstrument(path){
  fname = getFileNameWithoutExtension(path);
  if( matches(fname, "[A-Z][0-9]+--W[0-9]+--P[0-9]+--Z[0-9]+--T[0-9]+--.*" ) ){
    log_debug("Match Cellaview!! " + fname);
    return "CellaView";
  } else if( matches(fname, ".*_w[0-9](NIBA|WIGA|BF|NUA|WBV|NUA|CFP|RFP)")){
    log_debug("Match IX!! " + fname);
    return "IX";
  } else {
    log_error("Cannot determine the filter type:" + fname);
    return "";
  }
}


// creat directory recursively.
function mkdir_p(directory){
  // directory already exists, return
  if( File.isDirectory(directory)){
    return;
  }
  // if 'directory' is not directory, error.
  if( File.exists(directory)){
    log_error(directory + " is not directory. Stop macro.");
    exit(directory + " is not directory. Stop macro.");
  }
  // if parent directory does not exist, create it
  if(! File.isDirectory(File.getParent(directory))){
    mkdir_p(File.getParent(directory));
  }
  // create directory.
  log_debug("creat directory " + directory);
  File.makeDirectory(directory);
}

function close_window(title){
  selectWindow(title);
  run("Close");
}

function open_image(path){
  open(path);
  list = getList("image.titles");
  if( list.length == 0 ){
    return false;
  }
  id = getImageID();
  if(isOpen(id)){
    id = getImageID();
    name = File.getName(path);
    name = remove_special_chars(name);
    rename(name);
  }
  return id;
}

function remove_special_chars(string){
  ret = string;
  ret = replace(ret, " ", "_");
  ret = replace(ret, "[\\[\\]\\(\\)\\{\\};:\\+\\*\\$\\#\"\\&\'\\|\\!]", "_");
  ret = replace(ret, "__*", "_");
  ret = replace(ret, "_-_", "_");
  ret = replace(ret, "_\\.", ".");
  return ret;
}

function close_image(id){
  selectImage(id);
  if( isOpen(id) ){
    close();
  }
}

/*
function measureRGB(){
  if (bitDepth!=24)
     exit("This macro requires an RGB image");
  setRGBWeights(1, 0, 0);
  run("Measure");
  setResult("Label", nResults-1, "Red");
  setRGBWeights(0, 1, 0);
  run("Measure");
  setResult("Label", nResults-1, "Green");
  setRGBWeights(0, 0, 1);
  run("Measure");
  setResult("Label", nResults-1, "Blue");
  setRGBWeights(1/3, 1/3, 1/3);
  run("Measure");
  setResult("Label", nResults-1, "(R+G+B)/3");
  // weights uses in ImageJ 1.31 and earlier
  setRGBWeights(0.299, 0.587, 0.114);
  run("Measure");
  setResult("Label", nResults-1, "0.299R+0.587G+0.114B");
  updateResults();
}
*/

// 現在選択されている画像のminimum intensity を返す.
function get_min_int(){
  min = 0;
  dummy = 0;
  getStatistics(dummy, dummy, min, dummy, dummy , dummy);
  return min;
}
// 現在選択されている画像のmaximum intensity を返す.
function get_max_int(){
  max = 0;
  dummy = 0;
  getStatistics(dummy, dummy, dummy, max, dummy , dummy);
  return max;
}

// 現在選択されている画像のフィルタ名を取得
// とりあえず Cytell と IX81 でそれっぽいものを選ぶ
function get_filter_name(){
  title = getTitle();
  log_info("title = " + title);
  filter = "";
  if ( matches(title, ".*_w[0-9](NIBA|WIGA|BF|NUA|WBV|NUA|CFP|RFP).*") ){
    filter = replace(title, ".*_w[0-9]", "");
  } else if( matches(title, ".*(Cy5|FITC|Transillumination|Cy3|TexasRed).*$") ){
    if( matches(title, ".*Cy5.*") ){
      filter = "Cy5";
    } else if ( matches(title, ".*FITC.*") ){
      filter = "FITC";
    } else if ( matches(title, ".*Transillumination.*") ){
      filter = "BF";
    } else if ( matches(title, ".*Cy3.*") ){
      filter = "Cy3";
    } else if ( matches(title, ".*TexasRed.*") ){
      filter = "TexasRed";
    } else if ( matches(title, ".*DAPI.*") ){
      filter = "DAPI";
    } else {
      filter = "unmatch0";
    }
  } else {
    filter = "unmatch1";
  }
  return filter;
}

// 現在の選択の周囲の長さを取得する
function get_perimeter(){
  // run("Set Measurements...", " perimeter");
  run("Measure");
  perim = getResult("Perim.", nResults-1);
  // run("Clear Results");
  return perim;
}


// return min & max
function interactiveSetting(image_path){
  setting = newArray(3);
  id = open_image(image_path);
  selectImage(id);
  run("Channels Tool... ");
  waitForUser("Tone Setting",
      "Adjust color of the image by \"Channels\" window.\n" +
      "Click \"OK\", and then this macro will process all images with adjusted color balance above.\n" +
      "(\"Color\" window may be concealed by Image window.\n"
      );
  
  run("Color Balance...");
  waitForUser("Tone Setting",
      "Adjust color balance of an image by \"Color\" window.\n" +
      "Click \"OK\", and then this macro will process all images with adjusted color balance above.\n" +
      "(\"Color\" window may be concealed by Image window.\n" +
      "You can also open the \"Color\" window from Image->Adjust->Color Balance...)\n" +
      "Since this macro will process all image using the same color balance,\n" +
      "adjustment for dark image may cause white-out bright images.\n" +
      "First, try (min, max) = (0, 4095). This setting will produce the raw images captured by CCD camera."
      );
  getMinAndMax(setting[0], setting[1]);

  // color setting.
  run("RGB Color");
  cur_fcolor = getValue("color.foreground");
  cur_frgb   = getValue("rgb.foreground");
  cur_bcolor = getValue("color.background");
  cur_brgb   = getValue("rgb.background");
  log_debug("getValue(\"color.foreground\") = " + cur_fcolor);
  log_debug("getValue(\"rgb.foreground\") = " + cur_frgb);
  log_debug("getValue(\"color.background\") = " + cur_bcolor);
  log_debug("getValue(\"color.background\") = " + cur_brgb);
  setting[2] = cur_frgb;
  close_image(id);
  close_window("Color");
  return setting;
}

function get_config_file(name){
  home_dir = getDirectory("home");
  sep = File.separator;
  imagej_dir1 = home_dir + ".ImageJ";
  imagej_dir2 = home_dir + ".imagej";
  plugin_dir1 = imagej_dir1 + sep + "plugins";
  plugin_dir2 = imagej_dir2 + sep + "plugins";
  config_dir = "";
  if(File.exists(plugin_dir1) ){
    config_dir  = imagej_dir1 + sep + "config" + sep + name;
  } else if(File.exists(plugin_dir2) ){
    config_dir  = imagej_dir2 + sep + "config" + sep + name;
  }  else if(File.exists(imagej_dir1) ){
    config_dir  = imagej_dir1 + sep + "config" + sep + name;
  }  else if(File.exists(imagej_dir2) ){
    config_dir  = imagej_dir2 + sep + "config" + sep + name;
  } else {
    config_dir  = imagej_dir2 + sep + "config" + sep + name;
  }
  if(!File.exists(config_dir)){
    mkdir_p(config_dir);
  }
  config_file = config_dir + sep + "config.txt";
  return config_file;
}

// 設定をロードする関数(単純にファイルから開業区切りで文字列を取るだけ)
function load_config(name){
  config_file = get_config_file(name);

  if(File.exists(config_file)){
    configs = split(File.openAsString(config_file), "\n");
    len = configs.length;
    params = newArray(len);
    
    for(i=0; i < len; i++){
      // 1 == true, 0 == false 等価
      log_info("configs[" + i + "] = " + configs[i]);
      params[i] = configs[i];
    }
    return params;
  }
  return newArray(0);
}

// パラメータ params にarrayで渡すこと
function save_config(name, params){
  config_file = get_config_file(name);
  f = File.open(config_file);
  if(f == false){
    return false;
  }
  log_info("in save_config");

  len = params.length;
  Array.print(params);
  for(i=0; i < len; i++){
    // 1 == true, 0 == false 等価
    log_info("param => " + params[i]);
    print(f, params[i]);
  }
  File.close(f);
}

function get_result_string(){
  headings = split(String.getResultsHeadings);
  lines = "";
  for(row=0; row < nResults; row++){
    id_number = row + 1;
    line = "" + id_number + "\t" + getResultLabel(row);
    for(col=1; col < lengthOf(headings); col++){
      line = line + "\t" +  getResult(headings[col], row);
    }
    if(lines == ""){
      lines = line;
    } else { 
      lines = lines + "\n" + line;
    }
  }
  return lines;
}




// main script

config = load_config("CountEcoliColony");
default = newArray("1", "0", "100", "1", "20-250", "0.8-1", 0); // interval, white_background, ball_size, watershed, size, circ, remove_outline
if(config.length != default.length){
  config = default;
}


Dialog.create("Subtraction setting.");
Dialog.addMessage("Macros can be stopped by ESC");
Dialog.addNumber("interval", config[0]);
Dialog.addCheckbox("light background?", config[1]);
Dialog.addNumber("ball", config[2]);
Dialog.addCheckbox("Do watershed?", config[3]);
Dialog.addString("size (default 50-250)", config[4]);
Dialog.addString("circularity (default 0.5-1, max 1)", config[5]);
Dialog.addNumber("Ignore outline pixel. (60 pixel may be good).", config[6]);
Dialog.show();
config[0] = Dialog.getNumber();   // interval
config[1] = Dialog.getCheckbox(); // light
config[2] = Dialog.getNumber();   // ball
config[3] = Dialog.getCheckbox(); // watershed
config[4] = Dialog.getString();   // size
config[5] = Dialog.getString();   // circ
config[6] = Dialog.getNumber();   // ignore outline

save_config("CountEcoliColony", config);

interval = parseInt(config[0]);
light = config[1];
ball  = config[2];
watershed = config[3];
size  = config[4];
circularity = config[5];
outline = parseInt(config[6]);


roiManager("add");
roi_index = roiManager("count");

select_x = 0;
select_y = 0;
select_width    = 0;
select_height   = 0;
Roi.getBounds(select_x, select_y, select_width, select_height);
center_x = select_width / 2 + select_x;
center_y = select_height / 2 + select_y;
inside_x      = select_x + outline;
inside_y      = select_y + outline;
inside_width  = select_width  - 2 * outline;
inside_height = select_height - 2 * outline;

original_id = getImageID();
selectImage(original_id);
info_wait(interval);
// 一旦選択を外してから全体を使ってbackground補正する.
run("Select None");
run("Duplicate...", "title=cropped_imate.tif");
info_wait(interval);
duplicate_id = getImageID();
info_wait(interval);
selectImage(duplicate_id);
info_wait(interval);

if(ball > 0 ){
  if(light){
    run("Subtract Background...", "rolling=" + ball + " light");
  } else {
    run("Subtract Background...", "rolling=" + ball);
  }
}

info_wait(interval);
selectImage(original_id);
info_wait(interval);
if( outline > 0 ){
  makeOval(inside_x, inside_y, inside_width, inside_height);
} else {
  roiManager("select", roi_index - 1);
}
info_wait(interval);
run("Crop");

selectImage(duplicate_id);
info_wait(interval);
if( outline > 0 ){
  makeOval(inside_x, inside_y, inside_width, inside_height);
} else {
  roiManager("select", roi_index - 1);
}
info_wait(interval);
run("Crop");
run("Make Inverse");
run("Fill", "slice");
run("8-bit");
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
run("Select None");


waitForUser("Set threshold");
run("Threshold...");
//setAutoThreshold("Default");
run("Convert to Mask");
if( watershed ){
  log_info("Do watershed");
  run("Watershed");
} else {
  log_info("Do watershed");
}
run("Create Selection");
bin_id = getImageID();

//setAutoThreshold("Moments");
//setAutoThreshold("Default");
//run("Create Selection");
//run("Analyze Particles...", "size=50-250 circularity=0.50-1.00 show=Outlines display clear");
//run("Analyze Particles...", "size=50-250 circularity=0.50-1.00 show=Nothing display clear");
run("Analyze Particles...", "size=" + size + " circularity=" + circularity + " show=Masks display clear");
mask_id = getImageID();
selectImage(bin_id);
close();
selectImage(mask_id);
wait(2000);
run("Invert", "slice");
run("Images to Stack", "name=Stack title=[] use");

