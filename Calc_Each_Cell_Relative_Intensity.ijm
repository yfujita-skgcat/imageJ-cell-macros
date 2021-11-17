
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


macro "Calculate each cell relative intensity..." {
  print("\\Clear");

  src_dir = getDirectory("Select input directory.");
  result_file = replace(src_dir, "\\" + File.separator + "*$", "") + ".tsv";
  log_file = replace(src_dir, "\\" + File.separator + "*$", "") + ".log";
  File.saveString(getInfo("log"), log_file);
  log_info("Calc_Each_Cell_Relative_intensity Ver 2.0.3");
  log_info("Authors:: Yoshihiko Fujita   (yoshihiko.fujita@cira.kyoto-u.ac.jp)");
  log_info("Copyright:: Copyright (C) 2016 Yoshihiko Fujita. All rights reserved.");
  log_info("License:: BSD licence");

  // ファイル変換後の形式のCheckboxGroup設定.
  items = newArray(4);
  items[0] = "jpeg";
  items[1] = "tiff";
  items[2] = "gif";
  items[3] = "png";

  // logging
  log_levels = newArray(5);
  log_levels[0] = "debug";
  log_levels[1] = "info";
  log_levels[2] = "warn";
  log_levels[3] = "error";
  log_levels[4] = "fatal";

  sat_int = newArray(2);
  sat_int[0] = "4095";
  sat_int[1] = "65535";

  nuc_thres_method = newArray(23);
  nuc_thres_method[0]  = "Huang";
  nuc_thres_method[1]  = "RenyiEntropy";
  nuc_thres_method[2]  = "100";
  nuc_thres_method[3]  = "150";
  nuc_thres_method[4]  = "200";
  nuc_thres_method[5]  = "250";
  nuc_thres_method[6]  = "300";
  nuc_thres_method[7]  = "350";
  nuc_thres_method[8]  = "400";
  nuc_thres_method[9]  = "450";
  nuc_thres_method[10] = "500";
  nuc_thres_method[11] = "600";
  nuc_thres_method[12] = "700";
  nuc_thres_method[13] = "800";
  nuc_thres_method[14] = "900";
  nuc_thres_method[15] = "1000";
  nuc_thres_method[16] = "1100";
  nuc_thres_method[17] = "1200";
  nuc_thres_method[18] = "1300";
  nuc_thres_method[19] = "1400";
  nuc_thres_method[20] = "1500";
  nuc_thres_method[21] = "1600";
  nuc_thres_method[22] = "1700";

  // default value
  def_nuc_thres  = "Huang";
  def_max_int    = "4095";
  def_rel_filter = ".*TexasRed.*$";
  def_rel_ball   = 0;
  def_ref_filter = ".*DAPI.*$";
  def_ref_ball   = 200;
  def_watershed  = 0.5;
  def_subdir     = false; // false
  def_batch      = false; // false
  def_interval   = 1;

  config = load_config("CalcEachRelativeIntensity");
  default = newArray("0", "0", "1", "2", "info", "Huang", "700-10000", "0.5-1.00", ".*DAPI.*$", "0", ".*FITC.*$", "0", "200", "2", "4095", "-2", "-1", "");
  if(config.length != default.length){
    config = default;
  }


  Dialog.create("Settings.");
  Dialog.addMessage("Macros can be stopped by ESC");
  Dialog.addCheckbox("Calculate all files in subdirectories?",                                                   config[0]);
  Dialog.addCheckbox("Batch mode",                                                                               config[1]);
  Dialog.addCheckbox("Save region-marked PING images.",                                                          config[2]);
  Dialog.addNumber("Interval each step (sec, ignore if bachmode)",                                               config[3]);
  Dialog.addChoice("log level",  log_levels,                                                                     config[4]);
  Dialog.addChoice("Nucleus threshold method", nuc_thres_method,                                                 config[5]);
  Dialog.addString("Size of nuclei (i.e. 0-infinity)",                                                           config[6]);
  Dialog.addString("Circularity of nuclei (i.e. 0.20-1.00)",                                                     config[7]);
  Dialog.addString("Target filter image (regular expression):",                                                  config[8]);
  Dialog.addNumber("Subtract background for Target (ball radius, 0 is OFF, default 0):",                         config[9]);
  Dialog.addString("Reference filter image (regular expression):",                                               config[10]);
  Dialog.addNumber("Subtract background for Reference (ball radius, 0 is OFF, default 0):",                      config[11]);
  Dialog.addNumber("Subtract background for Recognition of cell region (ball radius, 0 is OFF, default 200):",   config[12]);
  if(File.exists(getDirectory("plugins") + File.separator + "Adjustable_Watershed.class")){
    Dialog.addNumber("Watershed value (Adjustable_Watershed.class exists: default 0.5):",                        config[13]);
  } else {
    Dialog.addNumber("Watershed value (NOTFOUND: Adjustable_Watershed.class in plugins folder):",                config[13]);
  }
  Dialog.addChoice("Saturated intensity:",  sat_int,                                                             config[14]);
  Dialog.addNumber("Cytoplasm distance from nuclei",                                                             config[15]);
  Dialog.addNumber("Thickness of cytoplasm",                                                                     config[16]);
  Dialog.addString("Exclude file (regular expression, blank = disable):",                                        config[17]);

  Dialog.show();

  config[0]  = Dialog.getCheckbox(); // subdir
  config[1]  = Dialog.getCheckbox(); // batch
  config[2]  = Dialog.getCheckbox(); // save or not PING images
  config[3]  = Dialog.getNumber(); // interval
  config[4]  = Dialog.getChoice(); // log level
  config[5]  = Dialog.getChoice(); // nuclear threshold method
  config[6]  = Dialog.getString(); // nuclear size
  config[7]  = Dialog.getString(); // nuclear circularity
  config[8]  = Dialog.getString(); // target filter
  config[9]  = Dialog.getNumber(); // target ball
  config[10]  = Dialog.getString(); // ref filter
  config[11]  = Dialog.getNumber(); // ref ball
  config[12]  = Dialog.getNumber(); // recog cell ball
  config[13]  = Dialog.getNumber(); // watershed value
  config[14] = Dialog.getChoice(); // Sat int
  config[15] = Dialog.getNumber(); // distance from nuclei
  config[16] = Dialog.getNumber(); // thickness of cytoplasm
  config[17] = Dialog.getString(); // Exclude file

  save_config("CalcEachRelativeIntensity", config);

  recursive     = config[0];
  batchmode     = config[1];
  save_ping     = config[2];
  interval      = config[3];
  log_level_str = config[4];
  thres_method  = config[5];
  nuc_size      = config[6];
  nuc_circ      = config[7];
  rel_filter    = config[8];
  rel_ball      = config[9];
  ref_filter    = config[10];
  ref_ball      = config[11];
  rec_ball      = config[12];
  if(File.exists(getDirectory("plugins") + File.separator + "Adjustable_Watershed.class")){
    watershed   = config[13];
  } else {
    watershed   = -1;
  }
  max_int       = config[14];
  distance      = config[15];
  thickness     = config[16];
  exclude       = config[17];

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

  log_info("max_int = " + max_int);
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
  rel_images = newArray(0);
  ref_images = newArray(0);
  for(i=0; i < file_list.length; i++){
    fpath = file_list[i];
    fname = File.getName(fpath);
    if(matches(fname, exclude)){
      log_info("Exclude file: " + fpath);
    } else if(matches(fname, rel_filter)){
      rel_images = Array.concat(rel_images, fpath);
    } else if(matches(fname, ref_filter)){
      ref_images = Array.concat(ref_images, fpath);
    } else {
      log_info("?? " + fpath);
    }
  }
  if(rel_images.length != ref_images.length){
    log_info("Error: The number mismatch. target files = " + rel_images.length + ", reference files = " + ref_images.length);
    return 0;
  }

  run("Colors...", "foreground=white background=black selection=green");
  run("Clear Results");
  run("Set Measurements...", "area mean standard min centroid center perimeter bounding fit shape feret's integrated median stack display redirect=None decimal=3");
  for(i=0; i < rel_images.length; i++){
    rel_image_dir = File.getParent(rel_images[i]);
    ref_image_dir = File.getParent(ref_images[i]);
    if(rel_image_dir == ref_image_dir){
      log_info("rel_image: " + File.getName(rel_images[i]));
      log_info("ref_image: " + File.getName(ref_images[i]));
      calc_rel(rel_images[i], ref_images[i], rel_ball, ref_ball, rec_ball, interval, max_int, watershed, thres_method, nuc_size, nuc_circ, distance, thickness, save_ping);
    } else {
      log_info("Files are in different directories.");
      log_info("rel_image: " + rel_images[i]);
      log_info("ref_image: " + ref_images[i]);
    }
    if( i == 0){
      //headings = split(String.getResultsHeadings);
      log_info("Writing to " + result_file);
      saveAs("Results", result_file);
      run("Clear Results");
      //File.saveString(getInfo("log"), log_file);
      //print("\\Clear");
    } else {

      log_info("Add results to " + result_file);
      File.append(get_result_string(), result_file);
      run("Clear Results");

      current_memory = parseInt(IJ.currentMemory())/1024/1024; // mega bytes
      max_memory = parseInt(IJ.maxMemory())/1024/1024;
      log_info("Memory usage: " + current_memory + " M bytes / max: " + max_memory + " M bytes");
      if( (((i+1) % 10) == 0 ) || current_memory > (max_memory - 100) ){ // 400 MByte 以上でlogを書き込んでclear
        File.append(getInfo("log"), log_file);
        print("\\Clear");
      }
    }
  }


  // save log to log_file
  log_info("***************************** ANALYSIS END ***********************************************");
  log_info("Save log to " + log_file);
  log_info("Analysis finished. Please see result file: " + result_file);
  log_info("******************************************************************************************");
  File.append(getInfo("log"), log_file);
  //File.saveString(getInfo("log"), log_file);

  close_all_images();

  setBatchMode(false);
}


// rel: 割られる画像(path)
// ref: 割る画像(path)
function calc_rel(relpath, refpath, rel_ball, ref_ball, rec_ball, interval, max_int, watershed, thres_method, nuc_size, nuc_circ, distance, thickness, save_ping){
  log_info("Closing all images...");
  close_all_images();
  roiManager("reset");

  rel_id = open_image(relpath);
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(rel_ball > 0){
    selectImage(rel_id);
    log_info("Target image \"" + getTitle() + "\" subtract background with " + rel_ball);
    run("Subtract Background...", "rolling=" + rel_ball);
  }
  relmax_id = open_image(relpath); // 4095 領域を検索用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

  ref_id = open_image(refpath);
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(ref_ball > 0){
    selectImage(ref_id);
    log_info("Reference image \"" + getTitle() + "\" subtract background with " + ref_ball);
    run("Subtract Background...", "rolling=" + ref_ball);
  }
  refmax_id = open_image(refpath); // 4095 領域を検索用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

  rec_id    = open_image(refpath); // 細胞領域検出用
  run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
  if(rec_ball > 0){
    selectImage(rec_id);
    log_info("Subtracting the background of the recognition-image \"" + getTitle() + "\" with " + rec_ball + " for defining cell region");
    run("Subtract Background...", "rolling=" + rec_ball);
  }

  
  // 画像のopenの順番(stack)は
  // 1. rel (background substraction)
  // 2. relmax (4095用, raw image)
  // 3. ref (background substraction)
  // 4. refmax(4095用, raw image)
  // 5. rec (領域認識用)
  // 6. divided of (rel/ref)
  // 7. binary image of rec
  slice_rel = 1;
  slice_relmax = 2;
  slice_ref = 3;
  slice_refmax = 4;
  slice_rec = 5;
  slice_div = 6;
  slice_bin = 7;

  // 割った画像を作成
  imageCalculator("Divide create 32-bit", rel_id, ref_id);
  div_id = getImageID();
  selectImage(div_id);
  //log_info("Info of Div image = " + getImageInfo());

  relname = File.getName(relpath);
  refname = File.getName(refpath);
  directory = File.getParent(relpath);
  relname = remove_special_chars(relname);
  calc_title = replace(relname, "\\.(tif|TIF|tiff|TIFF)$",  "_relative.tif");
  rename(calc_title);

  // rec_id を duplicate してbinaryを作ってみる
  selectImage(rec_id);
  run("Duplicate...", "title=binary");
  bin_id = getImageID();
  //info_wait(interval);

  setOption("BlackBackground", false);
  if( matches(thres_method, "^[0-9]+$") ){
    setThreshold(parseInt(thres_method), max_int);
  } else {
    setAutoThreshold(thres_method + " dark");
  }
  run("Make Binary");
  if(watershed > 0 ){ // adjustable watershed plugin がある場合はこちらを使う
    log_info("Adjustable Watershed:" + "tolerance=" + watershed);
    run("Adjustable Watershed", "tolerance=" + watershed);
  } else {
    run("Watershed");
  }
  info_wait(interval);

  // 解析対象の画像
  analysis_images = newArray(rel_id, ref_id, div_id);

  // 割る側から4095の領域を除く.
  //setSlice(slice_refmax); // 4095領域を探すstack
  selectImage(refmax_id); // 4095領域を探す画像
  setThreshold(max_int, max_int);
  run("Create Selection");
  if( selectionType() != -1 ){
    roiManager("Add");
    roiManager("select", 0);
    roiManager("Rename", "saturated");
    //setSlice(slice_bin); // 細胞認識のスタック, 今回はslice_bin
    selectImage(bin_id); // 細胞認識のスタック, 今回はslice_bin
    // いらないところを白(binary の場合, 白=intensity0)で塗る
    setForegroundColor(255, 255, 255);
    roiManager("select", 0);
    //run("Fill", "slice");
    fill();
    //run("Invert");
    info_wait(interval);
  }
  run("Select None");
  resetThreshold();

  // 割られる側の4095の領域を計算対象から外す
  // ために、割られる側の4095の領域と同じ割る側の領域を
  // 0にする.
  // 割られる側の4095領域を探す画像.
  //setSlice(slice_relmax);
  selectImage(relmax_id);
  setThreshold(max_int, max_int);
  roiManager("reset");
  run("Create Selection");
  if( selectionType() != -1 ){
    roiManager("Add");
    roiManager("select", 0);
    roiManager("Rename", "saturated");
    //setSlice(slice_bin); // 細胞認識のスタック, 今回はslice_bin
    selectImage(bin_id);
    // いらないところを白(binary の場合, 白=intensity0)で塗る
    setForegroundColor(255, 255, 255);
    roiManager("select", 0);
    fill();
    //run("Invert");
    info_wait(interval);
  }
  run("Select None");
  resetThreshold();


  selectImage(bin_id);
  log_info("Recognize objects.");
  info_wait(interval);

  // 手動の代わりにsetAutoThreshold で核認識
  setThreshold(1, 255);  // run("Make binary")を行っている場合は0以上で分ける
  log_info("Define regions by \"Analyze Particles... size=" + nuc_size + " circularity=" + nuc_circ + " show=Masks exlucde slice\"");
  run("Analyze Particles...", "size=" + nuc_size + " circularity=" + nuc_circ + " show=Masks exlucde slice");
  run("Clear Results");
  particle_id = getImageID();

  roiManager("reset");

  run("Create Selection");
  if( selectionType() == -1 ){
    log_info("No nuclei found. skip. File: " + relname );
    return 0;
  }
  info_wait(interval);

  roiManager("Add");
  roiManager("select", 0);
  roiManager("Rename", "nuclei");
  roiManager("Deselect");
  run("Select None");

  info_wait(interval);

  // distance 分核の領域を広げる/縮める
  if(distance < 0 ){
    log_info("Shrink nuclei (Erode x " + (-distance) + ")");
    for(j=0; j < -distance; j++){
      run("Erode");
    }
  } else {
    log_info("Enlarge nuclei (Dilate x " + distance + ")");
    for(j=0; j < distance; j++){
      run("Dilate");
    }
  }
  run("Create Selection");
  roiManager("Add");
  roiManager("select", 1);
  if(distance < 0 ){
    roiManager("Rename", "shrink_nuclei");
  } else {
    roiManager("Rename", "enlarge_nuclei");
  }

  info_wait(interval);

  roiManager("Add");
  roiManager("select", 2);
  run("Create Selection");
  run("Make Inverse");
  roiManager("Update");
  roiManager("Rename", "not_nuclei");
  roiManager("Deselect");
  run("Select None");

  info_wait(interval);


  if( thickness >= 0 ){
    // distance < 0 or thickness < 0 の時は核を解析すると言うことにとりあえずする.


    // thickness 分核の領域を広げる
    for(j=0; j < thickness; j++){
      //info_wait(interval);
      log_info("Enlarge nuclei (2nd)");
      run("Dilate");
    }
    run("Create Selection");
    roiManager("Add");
    roiManager("select", 3);
    roiManager("Rename", "nuclei_and_cytoplasm");
    roiManager("Deselect");
    run("Select None");

    info_wait(interval);

    // ROI Manager の 1:enlarge/shrink_nuclei, 3:nuclei_and_cytoplasm のXOR 片方だけで選択されている領域を取る.
    roiManager("select", newArray(1,3));
    roiManager("XOR");
    roiManager("Add");
    roiManager("select", 4);
    roiManager("Rename", "cytoplasm");
    roiManager("Deselect");
    run("Select None");

    info_wait(interval);

    // Not cytoplasm 
    roiManager("select", 4);
    roiManager("Add");
    roiManager("select", 5);
    run("Make Inverse");
    roiManager("Update");
    roiManager("Rename", "not_cytoplasm");
    roiManager("Deselect");
    run("Select None");

    info_wait(interval);
  }

  roi_number = roiManager("count");
  log_debug("roi number = " + roi_number);

  info_wait(interval);


  for(j = 0; j < analysis_images.length; j++){
    //log_info("Set to image ID:" + analysis_images[j]);
    selectImage(analysis_images[j]);
    log_info("Set to image " + getTitle());
    tmp_title = replace(getTitle(), "\\.(tif|TIF|tiff|TIFF)$",  "_1.tif");
    run("Duplicate...", "title=" + tmp_title);
    tmp_id = getImageID();

    //
    if(thickness < 0 ){
      roiManager("select", 1); // shrink/enlarge_nuclei の領域を選択
    } else {
      roiManager("Select", 4); // cytoplasm 領域を選択
    }
    darea = 0;
    dmean = 0;
    dmin = 0;
    dmax = 0;
    dstd = 0;
    dhistgram = 0;
    getStatistics(darea, dmean, dmin, dmax, dstd, dhistogram);

    if(thickness < 0 ){
      roiManager("select", 2); // not_nuclei 領域
    } else {
      roiManager("Select", 5); // not cytoplasm 領域を選択
    }

    info_wait(interval);
    setForegroundColor(0, 0, 0); // 背景を0 (black)で塗りつぶす
    info_wait(interval);
    //run("Fill", "slice");
    fill();
    
    info_wait(interval);
    run("Select None");
    info_wait(interval);
    log_info("intensity (min, max) = (" + dmin + ", " + dmax + "), setThreshold => (" + dmin/2 + ", " + max_int + ")");
    resetThreshold();
    setThreshold(dmin/2, max_int); 
    info_wait(interval);
    nsizes = split(nuc_size, "-");
    if( j == 0 ){
      // 解析対象領域をroiManagerに登録する(add)
      log_info("Start analyze particle...: size=0-" + nsizes[1] + " circularity=0.0-1.0 show=Nothing display exclude slice add");
      run("Analyze Particles...", "size=0-" + nsizes[1] + " circularity=0.0-1.0 show=Nothing display exclude slice add");
    } else {
      log_info("Start analyze particle...: size=0-" + nsizes[1] + " circularity=0.0-1.0 show=Nothing display exclude slice");
      run("Analyze Particles...", "size=0-" + nsizes[1] + " circularity=0.0-1.0 show=Nothing display exclude slice");
    }
    close_image(tmp_id);


    selectImage(analysis_images[j]);
    roiManager("Deselect");
    run("Select None");
    resetThreshold();

  }
  
  // nuclei, shrink/fat_nuclei とかの領域をroiManagerから削除する
  for(j=0; j < roi_number; j++){
    info_wait(interval);
    roiManager("Select", 0);
    roiManager("Delete");
  }

  if(save_ping){
    // save region-merged image (png)
    for(j = 0; j < analysis_images.length; j++){
      //log_info("Set to PING image (ID):" + analysis_images[j]);
      selectImage(analysis_images[j]);
      title = getTitle();
      log_info("Set to the Tiff image for a marked PING image:" + title);
      //roiManager("Show all with labels");
      setOption("Show All", true);
      run("Labels...", "color=white font=12 show draw bold");
      run("Flatten");
      tmp_id = getImageID();
      info_wait(interval);

      // 出力先ファイル名
      dst_path = directory + File.separator + replace(title, "\\.(tif|TIF|tiff|TIFF)$",  "_each.png");
      log_info("output to " + dst_path);
      if(interval == 0 && ! is("Batch Mode") ){
        info_wait(1);
      } else {
        info_wait(interval);
      }
      saveAs("PNG", dst_path);
      close_image(tmp_id);
    }
  }

  info_wait(interval);
  log_info("closing all images...");
  close_all_images();
}
