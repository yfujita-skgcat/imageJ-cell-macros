
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


macro "Merge channel tmp..." {
  print("\\Clear");

  src_dir = getDirectory("Select input directory.");
  dst_dir = getDirectory("Select ouput directory.");
  log_file = replace(src_dir, "\\" + File.separator + "*$", "") + ".log";
  File.saveString(getInfo("log"), log_file);
  log_info("Merge Channel macro  Ver 0.0.1");
  log_info("Authors:: Yoshihiko Fujita   (yoshihiko.fujita@cira.kyoto-u.ac.jp)");
  log_info("Copyright:: Copyright (C) 2018 Yoshihiko Fujita. All rights reserved.");
  log_info("License:: BSD licence");

  // ファイル変換後の形式のCheckboxGroup設定.
  items = newArray(1);
  items[0] = "tiff";

  // logging
  log_levels = newArray(5);
  log_levels[0] = "debug";
  log_levels[1] = "info";
  log_levels[2] = "warn";
  log_levels[3] = "error";
  log_levels[4] = "fatal";

  sat_int = newArray(2);
  sat_int[0] = "4095";
  sat_int[1] = "65534";

  // default value
  def_max_int       = "4095";
  def_channel1      = ".*Transillumination.*$";
  def_channel1_ball = 0;
  def_channel2      = ".*FITC.*$";
  def_channel2_ball = 200;
  def_channel3      = ".*Cy5.*$";
  def_channel3_ball = 200;
  def_subdir        = false; // false
  def_batch         = false; // false
  def_interval      = 1;

  config = load_config("MergeImage");
  default = newArray("0", "0", "5", "info", ".*Transillumination.*$", "0", ".*FITC.*$", "0", ".*Cy5.*$", "0");
  if(config.length != default.length){
    config = default;
  }

  Dialog.create("Settings.");
  Dialog.addMessage("Macros can be stopped by ESC");
  Dialog.addCheckbox("Calculate all files in subdirectories?", config[0]);
  Dialog.addCheckbox("Batch mode", config[1]);
  Dialog.addNumber("Interval each step (sec, ignore if bachmode)", config[2]);
  Dialog.addChoice("log level",  log_levels, config[3]);
  Dialog.addString("channel1 (regular expression):", config[4]);
  Dialog.addNumber("Subtract background for channel1 (ball radius, 0 is OFF, default 0):", config[5]);
  Dialog.addString("channel2 (regular expression):", config[6]);
  Dialog.addNumber("Subtract background for channel2 (ball radius, 0 is OFF, default 0):", config[7]);
  Dialog.addString("channel3 (regular expression):", config[8]);
  Dialog.addNumber("Subtract background for channel3 (ball radius, 0 is OFF, default 0):", config[9]);


  log_debug("===");
  Dialog.show();

  config[0]  = Dialog.getCheckbox(); // subdir
  config[1]  = Dialog.getCheckbox(); // batch
  config[2]  = Dialog.getNumber(); // interval
  config[3]  = Dialog.getChoice(); // log level
  config[4]  = Dialog.getString(); // channel1 filter
  config[5]  = Dialog.getNumber(); // channel1 ball
  config[6]  = Dialog.getString(); // channel2 filter
  config[7]  = Dialog.getNumber(); // channel2 ball
  config[8]  = Dialog.getString(); // channel3 filter
  config[9]  = Dialog.getNumber(); // channel3 ball

  save_config("MergeImage", config);

  recursive       = config[0];
  batchmode       = config[1];
  interval        = config[2];
  log_level_str   = config[3];
  channel1_filter = config[4];
  channel1_ball   = config[5];
  channel2_filter = config[6];
  channel2_ball   = config[7];
  channel3_filter = config[8];
  channel3_ball   = config[9];

  if(batchmode){
    log_info("batchmode = TRUE");
  } else {
    log_info("batchmode = FALSE");
  }

  if(log_level_str == "debug") {
    log_level = 1;
  } else if(log_level_str == "info") {
    log_level = 2;
  } else if(log_level_str == "warn") {
    log_level = 3;
  } else if(log_level_str == "error") {
    log_level = 4;
  } else if(log_level_str == "fatal") {
    log_level = 5;
  } else {
    log_fatal("log level not found. Enter unexpectd code.");
    return 0;
  }

  log_info("log level = " + log_level);

  file_list = find_recursive_dir(src_dir, recursive);

  if(file_list.length < 1){
    log_info("File not found.");
    return 0;
  }


  setBatchMode(batchmode);
  if(batchmode){
    interval = 0;
  }

  // image separation
  log_info("Starting file separation...");
  channel1_images = newArray(0);
  channel2_images = newArray(0);
  //channel3_images = newArray(0);
  for(i=0; i < file_list.length; i++){
    fpath = file_list[i];
    fname = File.getName(fpath);
    if(matches(fname, channel1_filter)){
      channel1_images = Array.concat(channel1_images, fpath);
    } else if(matches(fname, channel2_filter)){
      channel2_images = Array.concat(channel2_images, fpath);
    //} else if(matches(fname, channel3_filter)){
    //  channel3_images = Array.concat(channel3_images, fpath);
    } else {
      log_info("?? " + fpath);
    }
  }
  //if( !( channel1_images.length == channel2_images.length && channel2_images.length == channel3_images.length )){
  if( channel1_images.length != channel2_images.length ){
    log_info("Error: The number mismatch. channel files");
    return 0;
  }

  //run("Colors...", "foreground=white background=black selection=green");
  //run("Clear Results");
  //run("Set Measurements...", "area mean standard min centroid center perimeter bounding fit shape feret's integrated median stack display redirect=None decimal=3");

  log_info("Starting analysis...");
  for(i=0; i < channel1_images.length; i++){
    channel1_image_dir = File.getParent(channel1_images[i]);
    channel2_image_dir = File.getParent(channel2_images[i]);
    if(channel1_image_dir == channel2_image_dir){
      log_info("channel1_image: " + File.getName(channel1_images[i]));
      log_info("channel2_image: " + File.getName(channel2_images[i]));
      merge_image(channel1_images[i], channel2_images[i], dst_dir);
      // ここにmaerge いれる
    } else {
      log_info("Files are in different directories.");
      log_info("channel1_image: " + channel1_images[i]);
      log_info("channel2_image: " + channel2_images[i]);
    }
  }
  // save log to log_file
  log_info("***************************** ANALYSIS END ***********************************************");
  log_info("Save log to " + log_file);
  log_info("******************************************************************************************");
  File.append(getInfo("log"), log_file);
  //File.saveString(getInfo("log"), log_file);

  close_all_images();

  setBatchMode(false);
}

function merge_image(ch1, ch2, dst_dir){
  ch1_id = open_image(ch1);
  ch1_title = getTitle();
  ch2_id = open_image(ch2);
  ch2_title = getTitle();
  //run("Merge Channels...", "c2=[H - 08(fld 1 wv FITC - FITC).TIF] c4=[H - 08(fld 1 wv Transillumination - Blank1).TIF] create");
  str = "c2=" + ch2_title + " c4=" + ch1_title + " create";
  //run("Merge Channels...", "c2=" + ch1_title + " c4=" + ch2_title + " create");
  run("Merge Channels...", str);
  out_fname = dst_dir + File.separator + replace(ch1_title, "_wv_.*$", ".tif");
  log_info(out_fname);
  saveAs("tiff", out_fname);
  close_all_images();
}


// rel: 割られる画像(path)
// ref: 割る画像(path)
function calc_rel(relpath, refpath, rel_ball, ref_ball, rec_ball, interval, max_int, min_threshold){
  log_info("Closing all images...");
  close_all_images();

  rel_id = open_image(relpath);
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(rel_ball > 0){
    selectImage(rel_id);
    log_info("Target image subtract background with " + rel_ball);
    run("Subtract Background...", "rolling=" + rel_ball);
  }
  relmax_id = open_image(relpath); // 4095 領域を検索用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

  ref_id = open_image(refpath);
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(ref_ball > 0){
    selectImage(ref_id);
    log_info("Reference image subtract background with " + ref_ball);
    run("Subtract Background...", "rolling=" + ref_ball);
  }
  refmax_id = open_image(refpath); // 4095 領域を検索用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

  rec_id    = open_image(refpath); // 細胞領域検出用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(rec_ball > 0){
    selectImage(rec_id);
    log_info("Reference image subtract background with " + rec_ball + " for defining cell region");
    run("Subtract Background...", "rolling=" + rec_ball);
  }
  // 画像のopenの順番(stack)は
  // 1. rel
  // 2. relmax(4095用)
  // 3. ref
  // 4. refmax(4095)用
  // 5. div
  slice_rel = 1;
  slice_relmax = 2;
  slice_ref = 3;
  slice_refmax = 4;
  slice_rec = 5;
  slice_div = 6;

  imageCalculator("Divide create 32-bit", rel_id, ref_id);
  div_id = getImageID();
  selectImage(div_id);
  //log_info("Info of Div image = " + getImageInfo());

  relname = File.getName(relpath);
  refname = File.getName(refpath);
  directory = File.getParent(relpath);
  calc_title = relname + "/" + refname;
  rename(calc_title);
  info_wait(interval);
  run("Images to Stack", "name=Stack title=[] use");
  info_wait(interval);
  selectWindow("Stack");
  stack_id = getImageID();


  // 割る側から4095の領域を除く.
  info_wait(interval);
  setSlice(slice_refmax); // 4095領域を探すstack
  info_wait(interval);
  setThreshold(max_int, max_int);
  run("Create Selection");
  info_wait(interval);
  if( selectionType() != -1 ){
    //setSlice(slice_ref); // referenceのスタック
    setSlice(slice_rec); // 細胞認識のスタック
    info_wait(interval);
    setForegroundColor(0);
    run("Fill", "slice");
  }
  run("Select None");
  resetThreshold();

  // 割られる側の4095の領域を計算対象から外す
  // ために、割られる側の4095の領域と同じ割る側の領域を
  // 0にする.
  // 割られる側の4095領域を探す画像.
  setSlice(slice_relmax);
  info_wait(interval);
  setThreshold(max_int, max_int);
  run("Create Selection");
  info_wait(interval);
  if( selectionType() != -1 ){
    info_wait(interval);
    //setSlice(slice_ref);
    setSlice(slice_rec); // 細胞認識のスタック
    setForegroundColor(0);
    info_wait(interval);
    run("Fill", "slice");
    info_wait(interval);
    setSlice(slice_rel);
  }
  run("Select None");
  resetThreshold();


  info_wait(interval);
  //setSlice(slice_ref_max);
  setSlice(slice_rec);
  // もし、ref_ball == 0 (background subtractionを行っていない
  // 場合) ここで、ball == 200 でバックグラウンドを引いた画像
  // を作り、それを元にthresholdをきる.
  //if( ref_ball == 0){
  //  log_info("Reference image subtract background for threshold.");
  //  run("Subtract Background...", "rolling=200 slice");
  //}
  log_info("Recognize objects.");
  setThreshold(min_threshold, max_int);
  info_wait(interval);
  log_info("Create selection.");
  run("Create Selection");
  // 本当はここで小さな領域を除く処理をしたほうが良いが
  // 小さな領域ならそもそも平均への影響はほぼ無いので無視する
  // ヒント: make binary でanalyze particle でサイズ指定すると
  // 小さな領域は除けるようなのでできないことは無いはず. 要検討.
  info_wait(interval);
  if( selectionType() == -1 ){
    log_info("No object found. skip. File: " + relname );
  } else {
    setSlice(slice_div);
    info_wait(interval);
    run("Measure");
    setResult("Directory", nResults - 1,  directory);
    setResult("target", nResults - 1, relname);
    setResult("reference", nResults - 1, refname);
    info_wait(interval);
    log_debug("The number of current images: " + nImages() );
    log_debug("current Image: " + getImageID() + getImageInfo() );
    log_debug("active?: " + isActive(getImageID()));
  }
  info_wait(interval);
  close_all_images();
}
