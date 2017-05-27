require "mysql"
# require "mini_magick"
require "base64"
require "selenium-webdriver"

class RandValue
  attr_accessor :value
  attr_accessor :used
  def initialize
    @value=""
    @used=false
  end
end

class RandList
  def initialize
    @randlist = Array.new
    @usedcount = 0
  end

  def length
    return @randlist.length
  end

  def Clear
    @randlist.clear
  end

  def Add(value)
    valueUsed = RandValue.new
    valueUsed.value = value
    @randlist[@randlist.length] = valueUsed
  end

  def ReadDirectory(directory)
    begin
      @randlist.clear
      Dir.foreach(directory)  do |file|
        if (!File.directory?file)
          valueUsed = RandValue.new
          valueUsed.value = directory+"/"+file
          @randlist[@randlist.length] = valueUsed
        end
      end
      f_i.close
      f_i = nil
      @usedcount=0
      return true
    rescue
      return false
    end
  end

  def ReadFile(filename)
    begin
      @randlist.clear
      f_i = File.open(filename,"r")
      f_i.each{|line|
        if line.chomp.strip.length>0
          valueUsed = RandValue.new
          valueUsed.value = line.chomp
          @randlist[@randlist.length] = valueUsed
        end
      }
      f_i.close
      f_i = nil
      @usedcount=0
      return true
    rescue
      begin
        if(f_i!=nil)
          f_i.close
          f_i = nil
        end
      rescue
      end
      return false
    end
  end

  def RandValue
    begin
      if(@randlist.length>0)
        if(@usedcount >= @randlist.length)
          for i in 0..@randlist.length-1
            @randlist[i].used = false
          end
          @usedcount=0
        end
        pos = rand(@randlist.length)
        while(@randlist[pos].used)
          pos = (pos+1) % @randlist.length
        end
        @usedcount = @usedcount+1
        @randlist[pos].used = true
        return @randlist[pos].value
      else
        return ""
      end
    rescue
      return ""
    end
  end

end

class Log
  @@logfile = "log.txt"
  @@logtype = "All"
  def Log.LogSetting(logSetting)
    if(logSetting!=nil)
      if(logSetting["path"]!=nil)
        @@logfile =logSetting["path"]
      end
      if(logSetting["type"]!=nil)
        @@logtype =logSetting["type"]
      end
    end
  end

  def Log.WriteWarning(msg)
    Log.WriteMsg("Warning",msg)
  end

  def Log.WriteInfo(msg)
    Log.WriteMsg("Info",msg)
  end

  def Log.WriteError(msg)
    Log.WriteMsg("Error",msg)
  end
  private

  def Log.WriteMsg(type,msg)
    totalmsg = Time.new.strftime("%Y-%m-%d %H:%M:%S")+"["+type+"]"+msg
    if((@@logtype == "Normal" and (type=="Warning" or type=="Error")) or @@logtype == "All" or (@@logtype == "Less" and type=="Error"))
      puts totalmsg
    end
    f_o = File.open(@@logfile,"a")
    f_o.puts totalmsg
    f_o.close
  rescue
    puts "WriteLog Error!error:#{$!} at:#{$@}"
  end
end

class Browser
  attr_reader :proxyCurrentUse
  attr_reader :useragentCurrentUse
  def initialize(browserconfig)
    @browserconfig = browserconfig
  end

  def VerifConfig
    begin
      if(@browserconfig==nil or @browserconfig=="")
        Log.WriteError("Browser Config Not Exists.")
        return false
      end
      if(@browserconfig["type"]!=nil and @browserconfig["type"]!="")
        @type = @browserconfig["type"]
      else
        Log.WriteError("Browser Type Not Exists.")
        return false
      end
      @useremote = false
      if(@browserconfig["useremote"]==true)
        @useremote = true
        if(@browserconfig["remoteurl"]!=nil and @browserconfig["remoteurl"]!="")
          @remoteurl = @browserconfig["remoteurl"]
        else
          Log.WriteError("Remote Server is Uesd,But RemoteUrl Not Exists.")
          return false
        end
      end

      @proxy = RandList.new
      @noproxy =""
      if(@browserconfig["useproxy"]==true)
        if(@browserconfig["proxyfile"]==nil or @browserconfig["proxyfile"]=="")
          Log.WriteError("Proxy is Uesd,But ProxyFile Not Exists.")
          return false
        end

        if(!@proxy.ReadFile(@browserconfig["proxyfile"]))
          Log.WriteError("Read ProxyFile Error.FileName is #{@browserconfig["proxyfile"]}")
          return false
        end
      end

      if(@browserconfig["noproxy"]!=nil and @browserconfig["noproxy"]!="")
        @noproxy = @browserconfig["noproxy"]
      end

      @useragent = RandList.new
      if(@browserconfig["useuseragent"]==true)
        if(@browserconfig["useragentfile"]==nil or @browserconfig["useragentfile"]=="")
          Log.WriteError("UserAgent is Uesd,But UserAgentFile Not Exists.")
          return false
        end
        if(!@useragent.ReadFile(@browserconfig["useragentfile"]))
          Log.WriteError("Read UserAgentFile Error.FileName is #{@browserconfig["useragentfile"]}")
          return false
        end
      end
#设置图片显示（默认无）
      @noimage = false
      if(@browserconfig["noimage"]==true)
        @noimage = true
      end

      @loadingtimeout = 60
      if(@browserconfig["loadingtimeout"]!=nil and @browserconfig["loadingtimeout"]!="")
        @loadingtimeout = @browserconfig["loadingtimeout"]
      end

      @addextension =""
      if(@browserconfig["addextension"]!=nil and @browserconfig["addextension"]!="")
        @addextension = @browserconfig["addextension"]
      end

      return true
    rescue
      Log.WriteError("Browser Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

  def DriverCreate(proxy = nil,useragent = nil)
    begin
      if(proxy == nil or proxy=="")
        proxy = @proxy.RandValue
      end
      if(useragent == nil or proxy=="")
        useragent = @useragent.RandValue
      end
      remoteurl = ""
      if(@useremote)
        remoteurl = @remoteurl
      end
      case @type
      when "firefox"
        driver=FirefoxDriverCreate(proxy,@noproxy,remoteurl,useragent,@noimage)
      when "chrome"
        driver=ChromeDriverCreate(proxy,@noproxy,remoteurl,useragent,@noimage)
      when "phantomjs"
        driver =PhantomjsDriverCreate(proxy,@noproxy,remoteurl,useragent,@noimage)
      end
      if(driver != nil)
        @proxyCurrentUse = proxy
        @useragentCurrentUse = useragent
        driver.manage.timeouts.page_load=@loadingtimeout
        driver.manage.timeouts.implicit_wait=1
        driver.manage.delete_all_cookies
        driver.manage.window.maximize
        if(driver.manage.window.size.width<1024 and driver.manage.window.size.heigth<768)
          driver.manage.window.resize_to(1024, 768)
        end

      end
      return driver
    rescue
      Log.WriteError("Driver Create Failed!error:#{$!} at:#{$@}")
      return nil
    end
  end

  def Browser.CheckProxyEnable(driver,url,css)
    if(url==nil or url=="")
      return true
    end
    begin
      driver.get url
    rescue
      Log.WriteError("Open The Url #{url} Timeout")
      return false
    end
    begin
      driver.find_element(:css,css)
    rescue
      Log.WriteError("Cannot Find The Element By Css: #{css}")
      return false
    end
  rescue
    Log.WriteError("Check Proxy Enable Failed!error:#{$!} at:#{$@}")
    return false
  end

  def Browser.CheckElementNotExists(driver,elementcss)
    begin
      driver.find_element(:css,elementcss)
      return false
    rescue
      return true
    end
  end

  def Browser.SaveImage(driver,account)
    driver.save_screenshot("image/error/"+account+"."+Time.new.strftime("%Y%m%d%H%M%S")+".PNG")
  rescue
  end

  private

  def FirefoxDriverCreate(proxy,proxy_bypass,remoteurl,useragent,nodisplayimage)
    profile = Selenium::WebDriver::Firefox::Profile.new
    if (proxy !=nil and proxy != "")
      profile.proxy = Selenium::WebDriver::Proxy.new(
      :http     => proxy,
      :ftp      => proxy,
      :ssl      => proxy
      )
    end
    profile['network.proxy.no_proxies_on'] = proxy_bypass
    if(nodisplayimage)
      profile['permissions.default.image'] = 2
    end
    profile['privacy.clearOnShutdown.offlineApps'] = true
    profile['privacy.sanitize.sanitizeOnShutdown'] = true
    if(@addextension!=nil and @addextension!="")
      profile.add_extension(@addextension)
    end
    if (useragent != nil and useragent != "")
      profile['general.useragent.override'] = useragent
    end
    begin
      if (remoteurl == "" or remoteurl == nil)
        driver = Selenium::WebDriver.for :firefox, :profile => profile
      else
        capa = Selenium::WebDriver::Remote::Capabilities.firefox

        if remoteurl.scan("localhost").length == 0
          capa[:firefox_binary] = 'E:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe'
        end
        capa[:firefox_profile] = profile
        driver = Selenium::WebDriver.for :remote, :url => remoteurl, :desired_capabilities => capa
      end
      return driver
    rescue
      Log.WriteError("Driver Create Failed!error:#{$!} at:#{$@}")
      return nil
    end
  end

  def ChromeDriverCreate(proxy,proxy_bypass,remoteurl,useragent,nodisplayimage)
    begin
      prefs = {
        :profile => {
        :managed_default_content_settings => {
        #    :images => 2,
        :cookies =>4
        }
        }
      }
      if(nodisplayimage)
        prefs[:profile][:managed_default_content_settings][:images] =2
      end
      switches = Array.new
      switches.push("--disable-default-apps");
      if( proxy != nil and proxy != "")
        switches.push("--proxy-server="+proxy)
      end
      if( proxy_bypass != nil and proxy_bypass != "")
        switches.push("--proxy-bypass-list="+proxy_bypass)
      end
      if(useragent != nil and useragent != "")
        switches.push("--user-agent="+useragent)
      end
      if(remoteurl!=nil and remoteurl != "")
        caps = Selenium::WebDriver::Remote::Capabilities.chrome(:chromeOptions=>{:args=>switches,:prefs=>prefs})
        driver = Selenium::WebDriver.for :remote , :url=>remoteurl,:desired_capabilities=>caps
      else
        driver = Selenium::WebDriver.for :chrome , :prefs=>prefs,:switches=>switches
      end
      return driver
    rescue
      Log.WriteError("Driver Create Failed!error:#{$!} at:#{$@}")
      return nil
    end
  end

  def PhantomjsDriverCreate(proxy,proxy_bypass,remoteurl,useragent,nodisplayimage)
    begin
      phantomjs_caps ={}
      phantomjs_args= Array.new
      if(proxy!=nil and proxy !="")
        phantomjs_args.push("--proxy="+proxy)
        phantomjs_args.push("--proxy-type=http")
        phantomjs_args.push("--proxy-auth=x1auto:byp1205")
        if(proxy_bypass!=nil and proxy_bypass!="")
          phantomjs_args.push("--no-proxy="+proxy_bypass)
        end
      end
      if(nodisplayimage)
        phantomjs_caps["phantomjs.page.settings.loadImages"] = false
      end
      if(useragent!=nil and useragent!="")
        phantomjs_caps["phantomjs.page.settings.userAgent"] = useragent
      end
      if(phantomjs_args.length>0)
        phantomjs_caps["phantomjs.cli.args"] = phantomjs_args
      end
      puts phantomjs_caps
      driver = Selenium::WebDriver.for(:phantomjs, :desired_capabilities => phantomjs_caps)
      return driver
    rescue
      Log.WriteError("Phantomjs Driver Create Failed!error:#{$!} at:#{$@}")
      return nil
    end
  end
end

class ImagePoint
  attr_accessor:x
  attr_accessor:y
  def initialize
    @x=0
    @y=0
  end
end

class ImageHandle
  def ImageHandle.AddPoint(sourceImageFile,saveImageFile,pointSum)
    begin
      begin
        img = Magick::Image.read(sourceImageFile).first
      rescue
        return false
      end
      width = img.columns
      heigth = img.rows
      pointArray = Array.new
      pointCount=0
      for i in 1..width
        for j in 1..heigth
          point = ImagePoint.new
          point.x = i-1
          point.y = j-1
          pointArray[pointCount] = point
          pointCount = pointCount+1
        end
      end

      for i in 0..pointSum-1
        pos = i+rand(pointCount-i)
        point = pointArray[i]
        pointArray[i] = pointArray[pos]
        pointArray[pos] = point
      end
      color = ["red","blue","#EE7AE9","#EEA2AD","#EEEE00","#CAFF70","#00CDCD","#548B54","#76EEC6","#76EEC6"]
      addPoint = Magick::Draw.new
      for i in 1..pointSum
        x = pointArray[i-1].x
        y = pointArray[i-1].y
        addPoint.annotate(img,0,0,x,y,".") do
          self.pointsize = 5
          self.fill = color[rand(color.length)]
        end
      end
      img.write(saveImageFile)
      return true
    rescue
      Log.WriteError("Image Add Point Failed!error:#{$!} at:#{$@}")
      return false
    end
  end
end

####################################生成随机字符串
class Tools
  def Tools.RandString(regxString)
    len = 8+rand(5)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a    #.to_a 将range对象转换为Array数组对象
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size)] }    #再将数组内容改回字符串形式 使用upto方法
    return newpass
  rescue
    Log.WriteError("error:#{$!} at:#{$@}")
    return nil
  end

  def Tools.ReplaceConfig(config,sourceString,replaceString)
    $getbasepath = replaceString
    if(config.class == Hash)
      for i in 0..config.length-1
        if(config.values[i].class == String)
          str = config.values[i]
          if(str.include?sourceString)
          str[sourceString] = replaceString
          end
          config[config.keys[i]] = str
        else
          if(config.values[i].class == Hash)
            Tools.ReplaceConfig(config[config.keys[i]],sourceString,replaceString)
          end
        end
      end
    end
  rescue
    Log.WriteError("error:#{$!} at:#{$@}")
  end
end

class Domysql
  attr_accessor :loginaccount
  attr_accessor :loginpassword
  def initialize
    @loginaccount = ''
    @loginpassword = ''
  end

  def Domysql.insert_option(type,db_server,db_user,db_pwd,db_use,accountdata,reason)
    begin
      arry = accountdata.split('`')
      db = Mysql.real_connect(db_server,db_user,db_pwd)
      db.query("create database if not exists #{db_use} CHARACTER SET utf8")
      db.query("use #{db_use}")
      # db.options(Mysql::SET_CHARSET_NAME, 'utf8')
      db.query("SET NAMES 'utf8'")
      # db.query("drop table if exists account")
      # db.query("drop table if exists account_fail")
      if(arry[-1]=="true")
        domname = arry[3] + ".mozello.com"
        db.query("create table if not exists account(
            type varchar(30) not null default ' ',email varchar(50) not null default ' ',password varchar(50) default ' ',
            username varchar(50) default ' ',useragent varchar(200) default ' ',proxy varchar(30) default ' ',
            proxy_au varchar(50) default ' ',begintime datetime default null,endtime datetime default null,
            inserttime datetime,proc varchar(20) default ' ',state char(1) default ' ',dom varchar(50) default ' ',
            other1 varchar(200) default ' ',other2 varchar(200) default ' ',primary key(type,email))")
        db.query("insert into account(proc,inserttime,type,email,username,password,dom,proxy,useragent,begintime,endtime)
            values('#{$getbasepath}',now(),'#{type}','#{arry[0]}','#{arry[1]}','#{arry[2]}','#{domname}','#{arry[4]}','#{arry[5]}','#{arry[6]}','#{arry[7]}')")
      else
        db.query("create table if not exists account_fail(
            type varchar(30) not null default ' ',email varchar(50) not null default ' ',password varchar(50) default ' ',
            username varchar(50) default ' ',useragent varchar(200) default ' ',proxy varchar(30) default ' ',
            proxy_au varchar(50) default ' ',begintime datetime default null,endtime datetime default null,
            inserttime datetime,proc varchar(20) default ' ',reason varchar(1000) default ' ',
            primary key(type,email))")
        db.query("insert into account_fail(inserttime,type,email,username,password,proxy,useragent,begintime,endtime,proc,reason) 
            values(now(),'#{type}','#{arry[0]}','#{arry[1]}','#{arry[2]}','#{arry[4]}','#{arry[5]}','#{arry[6]}','#{arry[7]}','#{$getbasepath}','#{reason}')")
      end
      db.commit()
    rescue Mysql::Error=>e
      puts "Error code:#{e.errno}"
      puts "Error message:#{e.error}"
      puts "Error SQLSTATE:#{e.sqlstate}" if e.respond_to?("sqlstate")
    ensure
      db.close if db
    end
  end

  def Domysql.update_option(type,db_server,db_user,db_pwd,db_use,accountdata,reason)
    begin
      arry = accountdata.split('`')
      db = Mysql.real_connect(db_server,db_user,db_pwd,db_use)
      # db.options(Mysql::SET_CHARSET_NAME, 'utf8')
      db.query("SET NAMES 'utf8'")
      # db.query("drop table if exists account")
      # db.query("drop table if exists account_fail")
      if(arry[-1]=="true")
        ##不操作
      else
        db.query("update account set state = 'D' where type='#{type}' and email='#{arry[0]}' ")
      end
      db.commit()
    rescue Mysql::Error=>e
      puts "Error code:#{e.errno}"
      puts "Error message:#{e.error}"
      puts "Error SQLSTATE:#{e.sqlstate}" if e.respond_to?("sqlstate")
    ensure
      db.close if db
    end
  end
 
  def Readloginaccount(db_server,db_user,db_pwd,db_use,startline)
    begin
      db = Mysql.real_connect(db_server,db_user,db_pwd,db_use)
      res = db.query("SELECT email,password FROM account limit #{startline},1")
      while row = res.fetch_row do
          # puts "#{row}"
          @loginaccount = row[0]
          @loginpassword = row[1]
          puts row
      end
    rescue Mysql::Error=>e  
      puts "Error code:#{e.errno}"  
      puts "Error message:#{e.error}"  
      puts "Error SQLSTATE:#{e.sqlstate}" if e.respond_to?("sqlstate")  
    ensure  
      db.close if db
    end
  end

end