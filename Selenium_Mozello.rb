require 'mechanize'
require 'open-uri'

class MozelloAccount
  attr_accessor :host
  attr_accessor :account
  attr_accessor :password
  attr_accessor :screenname
  attr_accessor :mozellodom
  attr_accessor :username
  attr_accessor :proxy
  attr_accessor :useragent
  attr_accessor :issuccess
  attr_accessor :errorstep
  attr_accessor :errorreason
  attr_accessor :startTime
  attr_accessor :endTime
  def initialize
    @host=""
    @account = ""
    @password = ""
    @mozellodom = ""
    @username = ""
    @screenname = ""
    @proxy = nil
    @useragent = nil
    @issuccess = false
    @errorstep = ""
    @errorreason = ""
    @startTime =nil
    @endTime =nil
    @proxy_au=""
  end

#########################分析读取的文件####################
  def analyze(text)
    accountList = text.chomp.split("`")   #.chmop移除字符串末尾分隔符，如\n,  .split()分割
    @account = accountList[0]
    @username = accountList[1]
    @password = accountList[2]
    @mozellodom = accountList[3]
    @screenname = accountList[3]
    @proxy = accountList[4]
    @useragent = accountList[5]
    #####当文件账户用户为空时，默认为帐户名前缀
    if(@username==nil or @username=="")
    	@username = @account.split("@")[0].downcase()
    	if(@username == nil or @username =="")
    		Log.WriteError("Username Is Empty")
    		return false
    	end
    end
    ###########当文件文件账户不指定域名前缀时，自动生成。
    if(@mozellodom==nil or @mozellodom=="")
      @mozellodomregx = "[a-zA-Z]{4,20}"
      @mozellodom = Tools.RandString(@mozellodomregx)
      if(@mozellodom == nil or @mozellodom == "")
        Log.WriteError("Mozellodom Is Empty")
        return false
      end
    end
    return true
  rescue
    return false
  end

  def to_s()
    # return "#{@account}`#{@password}`#{@mozellodom}`#{@screenname}`#{@proxy}`#{@useragent}`#{@issuccess}`#{@startTime}`#{@endTime}`#{@errorstep}`#{@errorreason}"
    return "#{@account}`#{@username}`#{@password}`#{@mozellodom}`#{@proxy}`#{@useragent}`#{@startTime}`#{@endTime}`#{@errorstep}`#{@issuccess}"
  end

end

class MozelloAccounts
  def initialize(accountsconfig)
    @accountsconfig = accountsconfig
    @mozelloAccount = nil
    @mozelloAccounts = Array.new
    @mozelloAccountsIndex = 0
  end

  def VerifConfig
    begin
      if(@accountsconfig==nil or @accountsconfig=="")
        Log.WriteError("Accounts Config Not Exists.")
        return false
      end
      if(@accountsconfig["type"]==nil or @accountsconfig["type"]=="")
        Log.WriteError("Accounts Type Not Exists")
        return false
      end
      #########检验是否指定输出类型
      if(@accountsconfig["resultoutput"]==nil or @accountsconfig["resultoutput"]=="")
        Log.WriteError("Accounts Outputtype Not Exists")
        return false
      end
      ##################检验注册账户信息来源类型-----file or rand ##############
      @accountstype = @accountsconfig["type"]
      if(@accountstype!="rand" and @accountstype!="file")
        Log.WriteError("Accounts Type #{@accountstype} Not Defend")
        return false
      end
####################检验注册账户信息保存信息-----file or mysql###########
      @accountsoutputtype = @accountsconfig["resultoutput"]
      if(@accountsoutputtype!="file" and @accountsoutputtype!="mysql")
        Log.WriteError("Accounts Outputtype #{@accountsoutputtype} Not Defend")
        return false
      end
      #################后面生成sleeptime的范围
      @maxaccountspan = 10
      @minaccountspan = 10
      if(@accountsconfig["maxaccountspan"]!=nil and @accountsconfig["maxaccountspan"]!="")
        @maxaccountspan =@accountsconfig["maxaccountspan"]
      end
      if(@accountsconfig["minaccountspan"]!=nil and @accountsconfig["minaccountspan"]!="")
        @minaccountspan =@accountsconfig["minaccountspan"]
      end

  ############当账户文件设为随机生成，设置生成的范围##############
      if(@accountstype == "rand")
        @accountregx = "[a-zA-Z]{6,15}"
        @passwordregx = "[a-zA-Z]{10,15}"
        @usernameregx = "[a-zA-Z]{10,15}"
        @mozellodomregx = "[a-zA-Z]{4,20}"
        @usernameregx = "[a-zA-Z]{6,15}"
        ########当配置文件有参数数，优先使用config的数据，随机生成的无效########
        if(@accountsconfig["accountregx"]!=nil and @accountsconfig["accountregx"]!="")
          @accountregx = @accountsconfig["accountregx"]
        end
        if(@accountsconfig["passwordregx"]!=nil and @accountsconfig["passwordregx"]!="")
          @passwordregx = @accountsconfig["passwordregx"]
        end
        if(@accountsconfig["usernameregx"]!=nil and @accountsconfig["usernameregx"]!="")
          @usernameregx = @accountsconfig["usernameregx"]
        end
        if(@accountsconfig["mozellodomregx"]!=nil and @accountsconfig["mozellodomregx"]!="")
          @mozellodomregx = @accountsconfig["mozellodomregx"]
        end
        if(@accountsconfig["usernameregx"]!=nil and @accountsconfig["usernameregx"]!="")
          @mozellodomregx = @accountsconfig["usernameregx"]
        end
#########获取邮箱后缀###############
        @hosts = RandList.new
        if(@accountsconfig["hostfile"]==nil or @accountsconfig["hostfile"]=="")
          Log.WriteError("Account Register Is Need,But HostFile Not Exists.")
          return false
        end
        if(!@hosts.ReadFile(@accountsconfig["hostfile"]))
          Log.WriteError("Read HostFile Error.FileName is #{@accountsconfig["hostfile"]}")
          return false
        end
  ###########文件账户设为从文件获取，从config.accountfile: "account.txt"  读取账户信息##########
      else
        if(@accountsconfig["accountfile"]==nil or @accountsconfig["accountfile"]=="")
          Log.WriteError("Account Read From file,But Accounts File Not Exists.")
          return false
        end
        @mozelloAccountsIndex = 0
        if(@accountsconfig["accountindexfile"]==nil or @accountsconfig["accountindexfile"]=="")
          Log.WriteError("Account Read From file,But Accounts Index File Not Exists.")
          return false
        end
        @accountsindexfile = @accountsconfig["accountindexfile"]
        begin
          f_i = File.open(@accountsconfig["accountindexfile"],"r")

      ############@mozelloAccountsIndex  已被注册过的账号的个数###########
          @mozelloAccountsIndex = f_i.read.to_i   # to_i将字符串转为数值
          f_i.close
        rescue
          Log.WriteError("Account Index File Read Error.error:#{$!} at:#{$@}")
          return false
        end
        @mozelloAccounts.clear        #删除mozelloAccounts数组所有元素
        
#####################开始从account.txt获取账户信息#####################
        begin
          f_i = File.open(@accountsconfig["accountfile"],"r")
          f_i.each{|line|
            mozelloAccount = MozelloAccount.new
            if(mozelloAccount.analyze(line))
              #分别获取每行的信息,此处length会自增(0..n),每加一个账号,数组@mozelloAccounts长度+1
              @mozelloAccounts[@mozelloAccounts.length] = mozelloAccount
            else
              Log.WriteError("Account Input File Error. #{line} is Not Rigth Format")
              return false
            end
          }
          f_i.close
          if(@mozelloAccounts.length==0)
            Log.WriteError("Account Input File Do Not Have Record")
            return false
          end
        rescue
          Log.WriteError("Account Input File Read Error.error:#{$!} at:#{$@}")
        end
      end

      if(@accountsoutputtype=="file")
        if(@accountsconfig["resultfile"]==nil or @accountsconfig["resultfile"]=="")
          Log.WriteError("Account Result Not Setting.")
          return false
        end
        @result = @accountsconfig["resultfile"]
        return true
      else
        if(@accountsconfig["db_server"]==nil or @accountsconfig["db_server"]=="")
          Log.WriteError("DB_Server Not Setting")
          return false
        end
        @db_server = @accountsconfig["db_server"]
        if(@accountsconfig["db_user"]==nil or @accountsconfig["db_user"]=="")
          Log.WriteError("DB_User Not Setting")
          return false
        end
        @db_user = @accountsconfig["db_user"]
        if(@accountsconfig["db_pwd"]==nil)
          Log.WriteError("DB_Pwd Not Setting")
          return false
        end
        @db_pwd = @accountsconfig["db_pwd"]
        if(@accountsconfig["db_use"]==nil or @accountsconfig["db_use"]=="")
          Log.WriteError("DB_Use Not Setting")
          return false
        end
        @db_use = @accountsconfig["db_use"]
        return true
      end
    rescue
      Log.WriteError("MozelloAccounts Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

  def ReadAccount
    case @accountstype
    when "rand"
      return CreateAccount()
    when "file"
      return ReadFileAccount()
    end
  rescue
    Log.WriteError("ReadMozelloAccount Failed!error:#{$!} at:#{$@}")
    return false
  end

  def CurrentAccount
    return @mozelloAccount
  end

  def WriteResult
    if(@mozelloAccount!=nil)
      Log.WriteInfo(@mozelloAccount.to_s)
    ####################记录文件账号中已经注册的账号个数
      if(@accountstype=="file")
        f_o =File.open(@accountsindexfile,"w")
        f_o.puts @mozelloAccountsIndex
        f_o.close
      end
      if(@accountsoutputtype=="file")
        begin
          f_o = File.open(@result,"a")
          f_o.puts @mozelloAccount.to_s
          f_o.close
        rescue
        end
      else
        begin
          @type = "mozello"
          Domysql.insert_option(@type,@db_server,@db_user,@db_pwd,@db_use,@mozelloAccount.to_s,@mozelloAccount.errorreason)
        rescue
          puts "Failed!error:#{$!} at:#{$@}"
        end
      end
    end
  rescue
  end

  def GetSleepTime
    return @minaccountspan+rand(@maxaccountspan-@minaccountspan+1)
  rescue
    return 1
  end

  private

  def ReadFileAccount
    if(@mozelloAccounts!=nil and @mozelloAccountsIndex<@mozelloAccounts.length)
      @mozelloAccount = @mozelloAccounts[@mozelloAccountsIndex]
      @mozelloAccountsIndex = @mozelloAccountsIndex+1
      return true
    else
      @mozelloAccount = nil
      Log.WriteError("ReadFileMozelloAccount Failed!The Accounts File is end")
      return false
    end
  rescue
    @mozelloAccount = nil
    Log.WriteError("ReadFileMozelloAccount Failed!error:#{$!} at:#{$@}")
    return false
  end

################随机生成账号，密码，域名信息################
  def CreateAccount
    host = @hosts.RandValue
    if(host==nil or host=="")
      Log.WriteError("Host Is Empty.")
      return false
    end
######################################################账户邮箱
    account = Tools.RandString(@accountregx)
    if(account==nil or account =="")
      Log.WriteError("Account Is Empty")
      return false
    end
    password =Tools.RandString(@passwordregx)
    if(password==nil or password=="")
      Log.WriteError("Password Is Empty")
      return false
    end
    ################随机生成域名前缀################
    mozellodom = Tools.RandString(@mozellodomregx)
    if(mozellodom == nil or mozellodom == "")
      Log.WriteError("Mozellodom Is Empty")
      return false
    end

    # username = Tools.RandString(@usernameregx)
    # if(username == nil or username == "")
    #   Log.WriteError("Username Is Empty")
    #   return false
    # end
    screenname = Tools.RandString(@usernameregx)
    if(screenname ==nil or screenname=="")
      Log.WriteError("Screenname Is Empty")
      return false
    end
    @mozelloAccount = MozelloAccount.new
    @mozelloAccount.host=host
##################################################邮箱格式
    @mozelloAccount.account =account+"@"+@mozelloAccount.host
    @mozelloAccount.password = password
    @mozelloAccount.screenname = screenname
    @mozelloAccount.mozellodom = mozellodom.downcase()
    @mozelloAccount.username = account.downcase()
    return true
  rescue
    Log.WriteError("CeateMozelloAccount Failed!error:#{$!} at:#{$@}")
    return false
  end
end

#######################################登录时，从文件获取账户密码#####################################################################################
class MozelloLoginAccounts < MozelloAccounts
  def initialize(loginconfig,accountsconfig)
    @loginconfig = loginconfig
    @accountsconfig = accountsconfig
    @mozelloLoginAccount = nil
    @mozelloLoginAccounts = Array.new
    @mozelloLoginAccountsIndex = 0
  end

  def VerifConfig
    begin
      if(@loginconfig==nil or @loginconfig=="")
        Log.WriteError("LoginAccounts Config Not Exists.")
        return false
      end
      if(@loginconfig["logintype"]==nil or @loginconfig["logintype"]=="")
        Log.WriteError("LoginAccounts Type Not Exists")
        return false
      end
      #################获取登录账户类型##############
      @logintype = @loginconfig["logintype"]
      if(@logintype!="mysql" and @logintype!="file")
        Log.WriteError("LoginAccounts Type #{@accountstype} Not Defend")
        return false
      end

  #########从文件获取登录账号密码
      if(@logintype == "file")
        if(@loginconfig["loginfile"]==nil or @loginconfig["loginfile"]=="")
          Log.WriteError("LoginAccount Read From file,But Accounts File Not Exists.")
          return false
        end
        @mozelloLoginAccountsIndex = 0
        if(@loginconfig["loginindexfile"]==nil or @loginconfig["loginindexfile"]=="")
          Log.WriteError("Account Read From file,But LoginAccounts Index File Not Exists.")
          return false
        end
        @loginindexfile = @loginconfig["loginindexfile"]
        begin
          f_i = File.open(@loginconfig["loginindexfile"],"r")

      ############@mozelloLoginAccountsIndex  已登录过的账号个数###########
          @mozelloLoginAccountsIndex = f_i.read.to_i   # to_i将字符串转为数值
          f_i.close
        rescue
          Log.WriteError("LoginAccount Index File Read Error.error:#{$!} at:#{$@}")
          return false
        end
        @mozelloLoginAccounts.clear        #删除mozelloLoginAccounts数组所有元素
        
  #####################开始从loginfile指定的文件获取账户信息#####################
        begin
          f_i = File.open(@loginconfig["loginfile"],"r")
          f_i.each{|line|
            mozelloLoginAccount = MozelloAccount.new
            if(mozelloLoginAccount.analyze(line))
              @mozelloLoginAccounts[@mozelloLoginAccounts.length] = mozelloLoginAccount  #将账户密码等每行信息分别存储到mozelloAccounts,length自增
            else
              Log.WriteError("LoginAccount Input File Error. #{line} is Not Rigth Format")
              return false
            end
          }
          f_i.close
          if(@mozelloLoginAccounts.length==0)
            Log.WriteError("LoginAccount Input File Do Not Have Record")
            return false
          end
        rescue
          Log.WriteError("LoginAccount Input File Read Error.error:#{$!} at:#{$@}")
        end
      else
        if(@loginconfig["frommysqlindex"]==nil or @loginconfig["frommysqlindex"]=="")
          Log.WriteError("Account Read From mysql,But LoginAccounts Index File Not Exists.")
          return false
        end
        @loginindexfile = @loginconfig["frommysqlindex"]
        @mozelloLoginAccountsIndex = 0
        begin
          f_i = File.open(@loginconfig["frommysqlindex"],"r")
          @mozelloLoginAccountsIndex = f_i.read.to_i   # to_i将字符串转为数值
          # if(@mozelloLoginAccountsIndex == nil or @mozelloLoginAccountsIndex == '')
          #   @mozelloLoginAccountsIndex = 0
          # end
          f_i.close
        rescue
          Log.WriteError("LoginAccount Index File Read Error.error:#{$!} at:#{$@}")
          return false
        end
        @db_server = @accountsconfig["db_server"]
        @db_user = @accountsconfig["db_user"]
        @db_pwd = @accountsconfig["db_pwd"]
        @db_use = @accountsconfig["db_use"]
      end

      #############登录结果输出###
      @accountsoutputtype = @accountsconfig["resultoutput"]
      if(@accountsoutputtype=="file")
      	@result = @accountsconfig["resultfile"]
      else
      	@db_server = @accountsconfig["db_server"]
    		@db_user = @accountsconfig["db_user"]
    		@db_pwd = @accountsconfig["db_pwd"]
    		@db_use = @accountsconfig["db_use"]
      end
      return true
    rescue
      Log.WriteError("MozelloAccounts Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

  def ReadAccount
    case @logintype
    when "file"
        return ReadFileAccount()
    when "mysql"
      return ReadMysqlAccount()
    end
  rescue
    Log.WriteError("ReadMozelloLoginAccount Failed!error:#{$!} at:#{$@}")
    return false
  end
  def ReadFileAccount
    if(@mozelloLoginAccounts!=nil and @mozelloLoginAccountsIndex<@mozelloLoginAccounts.length)
      @mozelloAccount = @mozelloLoginAccounts[@mozelloLoginAccountsIndex]
      @mozelloLoginAccountsIndex = @mozelloLoginAccountsIndex+1
      return true
    else
      @mozelloAccount = nil
      Log.WriteError("ReadFileMozelloLoginAccount Failed!The Login Accounts File is end")
      return false
    end
  rescue
    @mozelloAccount = nil
    Log.WriteError("ReadFileMozelloAccount Failed!error:#{$!} at:#{$@}")
    return false
  end

  def ReadMysqlAccount
    login = Domysql.new
    login.Readloginaccount(@db_server,@db_user,@db_pwd,@db_use,@mozelloLoginAccountsIndex)
    @mozelloAccount = MozelloAccount.new
    @mozelloAccount.account = login.loginaccount
    @mozelloAccount.password = login.loginpassword
    if(@mozelloAccount.account == nil or @mozelloAccount.account == "")
        Log.WriteError("ReadFileMozelloAccount Failed!The Accounts File is end")
        return false
    end
    @mozelloLoginAccountsIndex = @mozelloLoginAccountsIndex + 1
    return true
  end

  def CurrentAccount
    return @mozelloAccount
  end

  def WriteResult
    if(@mozelloAccount!=nil)
      Log.WriteInfo(@mozelloAccount.to_s)
      begin
          ####记录账户文件已经登录过的账号个数
        f_o = File.open(@loginindexfile,"w")
        f_o.puts @mozelloLoginAccountsIndex
        f_o.close
      rescue
        puts "保存登录账户个数出错"
      end
      if(@accountsoutputtype=="file")
        begin
    			####记录结果
    			f_o = File.open(@result,"a")
    			f_o.puts @mozelloAccount.to_s
    			f_o.close
      	rescue
      		puts "结果保存失败，error：#{$!}, at:#{$@}"
      	end
      else
        begin
        	@type = "Mozello"
        	# Domysql.insert_option(@type,@db_server,@db_user,@db_pwd,@db_use,@mozelloAccount.to_s,@mozelloAccount.errorreason)
          Domysql.update_option(@type,@db_server,@db_user,@db_pwd,@db_use,@mozelloAccount.to_s,@mozelloAccount.errorreason)
        rescue
        	puts "Failed!error:#{$!} at:#{$@}"
        end
      end
    end
  rescue
  end

end
#####################################################################################################################################################

class MozelloRegister
  def initialize(registerconfig)
    @registerconfig = registerconfig
  end

  def VerifConfig
    begin
      if(@registerconfig!=nil)
        @waittime = 10
        if(@registerconfig["waittime"])
          @waittime = @registerconfig["waittime"].to_i
        end
        @trycaptcher = 5
        if(@registerconfig["trycaptcher"])
          @trycaptcher = @registerconfig["trycaptcher"].to_i
        end
        if(@registerconfig['TTS']['voicepath']==nil or @registerconfig['TTS']['voicepath']=="")
          puts 'TTS voicepath not set'
          return false
        end
        @voicepath = @registerconfig['TTS']['voicepath']
        if(!File.exist?(@voicepath))
            puts "not exist #{@voicepath} dir"
            return false
        end
        # @stt = STT.new(@registerconfig['TTS'])
        # if(!@stt.VerifConfig)
        #   return false
        # end
        return true
      end
    rescue
      Log.WriteError("MozelloRegister Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

#####注册类#######
  def Operate(driver,mozelloAccount)
    rtn = true
    Log.WriteInfo("-----------------------do Register Process----------------------")
    begin
      driver.get "http://www.mozello.com/session/signup/"
      Log.WriteInfo("get http://www.mozello.com/session/signup/ ok!")
    rescue
      Log.WriteError("get http://www.mozello.com/session/signup/ failed!")
      mozelloAccount.errorreason = "get http://www.mozello.com/ failed!"
    end

    # #获取当前窗口
    # nowhandle = driver.window_handle

    # 查找 注册按钮，找到则点击
    begin
      destsite = driver.find_element(:xpath,"/html/body/div[1]/form/div[1]/input")
      Log.WriteInfo("find E-mail address")
    rescue
      Log.WriteError("not find find E-mail address")
      mozelloAccount.errorreason = "not find find E-mail address" + '`' + mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      destsite.send_keys(mozelloAccount.account)
    end
    begin
      destsite = driver.find_element(:xpath,"/html/body/div[1]/form/div[2]/input")
      Log.WriteInfo("find Password input")
    rescue
      Log.WriteError("not find Password input")
      mozelloAccount.errorreason = "not find Password input" + '`' + mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      destsite.send_keys(mozelloAccount.password)
    end
    begin
      destsite = driver.find_element(:xpath,"/html/body/div[1]/form/ul/li/input")
      Log.WriteInfo("find find Create My Website")
    rescue
      Log.WriteError("not find Create My Website")
      mozelloAccount.errorreason = "not find Create My Website" + '`' + mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      destsite.click
    end

    wait = Selenium::WebDriver::Wait.new(:timeout=>@waittime,:interval=>1)
    begin
      wait.until{driver.find_element(:xpath,"/html/body/div[1]/form")}
    rescue
      mozelloAccount.errorreason = "用户已被注册" + '`' +mozelloAccount.errorreason
    end

#进入创建站点
    begin
      destsite = driver.find_element(:xpath,"/html/body/div[1]/form/div[1]/input")
      Log.WriteInfo("find Website title or brandname")
    rescue
      Log.WriteError("not find Website title or brandname")
      mozelloAccount.errorreason = "not find Website title or brandname" + '`' +mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      #清楚网站原来输入框的文本信息
      # destsite.clear()
      #输入域名前缀
      puts mozelloAccount.mozellodom
      destsite.send_keys(mozelloAccount.mozellodom)
    end
    begin
      #######################人机验证
      ###进入点击框，点击
      getframe = driver.find_element(:xpath,"//iframe[@title='recaptcha widget']")
      driver.switch_to.frame(getframe)
      element = driver.find_element(:css,".recaptcha-checkbox-checkmark")
      element.click
      ###返回原frame
      driver.switch_to.default_content
      ####进入验证内容
      ###使用绝对路径找不到该iframe,故使用相对路径
      wait.until{driver.find_element(:xpath,"//iframe[@title='recaptcha challenge']")}
      getframe2 = wait.until{driver.find_element(:xpath,"//iframe[@title='recaptcha challenge']")}
      # getframe2 = wait.until{driver.find_element(:xpath,"/html/body/div[5]/div[4]/iframe")}
      driver.switch_to.frame(getframe2)
      ###切换到语音验证
      element = driver.find_element(:css,"#recaptcha-audio-button")
      element.click
        ###返回原frame
      driver.switch_to.default_content
      getframe = driver.find_element(:xpath,"//iframe[@title='recaptcha widget']")
      driver.switch_to.frame(getframe)
      element = driver.find_element(:xpath,"/html/body/div[2]/div[3]/div[1]/div/div/span")
      trydeCaptcher = 0
      while(element.attribute("aria-checked")=="false" and trydeCaptcher<@trycaptcher)
        begin
        trydeCaptcher += 1
        ###返回原frame
        driver.switch_to.default_content
        ####进入验证内容
        getframe2 = driver.find_element(:xpath,"//iframe[@title='recaptcha challenge']")
        driver.switch_to.frame(getframe2)
        # ###切换到语音验证
        # element = driver.find_element(:xpath,"/html/body/div[1]/div/div[3]/div[2]/div[1]/div[1]/div[2]/div")
        # element.click
        element = driver.find_element(:css,".rc-audiochallenge-download-link")
        mp3link = element.attribute('href')

        mp3data = open(mp3link){|f|f.read}
        # puts mp3data
        open("#{@voicepath}/audio.mp3","w+"){|f|f.write(mp3data)}

        result = Main.start("#{File.dirname(__FILE__)}/#{@voicepath}")

        ###返回原frame
        driver.switch_to.default_content
        ####进入验证内容
        getframe2 = driver.find_element(:xpath,"//iframe[@title='recaptcha challenge']")
        driver.switch_to.frame(getframe2)
        sleep(0.5)
        rescue
          puts "#{$!}, at:#{$@}"
        end

        begin
          element = driver.find_element(:css,"#audio-response")
          element.send_keys(result)
          sleep(1)
          element = driver.find_element(:css,"#recaptcha-verify-button")
          element.click
          sleep(1)
        rescue
          puts "出错了#{$!}, at:#{$@}"
        end
        ####检验是否验证成功
        driver.switch_to.default_content
        getframe = driver.find_element(:xpath,"//iframe[@title='recaptcha widget']")
        driver.switch_to.frame(getframe)
        element = driver.find_element(:xpath,"/html/body/div[2]/div[3]/div[1]/div/div/span")
        if(element.attribute("aria-checked")=="false")
          puts "验证失败"
          # DeCaptcher.compensation(deCaptcherResult[1],deCaptcherResult[2])
          # puts '索赔处理完'
          ###刷新下验证码
          begin
            driver.switch_to.default_content
            getframe2 = driver.find_element(:xpath,"//iframe[@title='recaptcha challenge']")
            driver.switch_to.frame(getframe2)
            refresh = driver.find_element(:css,"#recaptcha-reload-button")
          rescue
            puts "error：#{$!}, at:#{$@}"
          end

          begin
          if(refresh==nil or refresh=="")
            puts 'not find refresh element'
          else
            refresh.click
            sleep(2)
            driver.switch_to.default_content
            ########切换到之前点击人机验证的位置，这样while才能判断
            getframe = driver.find_element(:xpath,"//iframe[@title='recaptcha widget']")
            driver.switch_to.frame(getframe)
            element = driver.find_element(:xpath,"/html/body/div[2]/div[3]/div[1]/div/div/span")
          end
            puts "refresh decaptcher"
          rescue
          end
        else
          begin
          puts "验证成功"
          # DeCaptcher.compensation(deCaptcherResult[1],deCaptcherResult[2])
          driver.switch_to.default_content
          break
          rescue
          end

        end
        if(trydeCaptcher==@trycaptcher)
          mozelloAccount.errorreason = "人机验证未通过" + '`' + mozelloAccount.errorreason
          return false
        end
      end
    rescue
      retry
      Log.WriteInfo("验证出现错误")
      mozelloAccount.errorreason = "验证出现错误" + '`' + mozelloAccount.errorreason
    end
##################################
    begin
      destsite = driver.find_element(:xpath,"/html/body/div[1]/form/ul/li/input")
      Log.WriteInfo("find Done")
    rescue 
      Log.WriteError("not find Done")
      mozelloAccount.errorreason = "not find Done" + '`' +mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      destsite.click
    end
    begin
    	wait.until{driver.find_element(:xpath,"/html/body/div[1]/h1")}
    rescue
      mozelloAccount.errorreason = "该站点已经被注册" + '`' +mozelloAccount.errorreason
    end

    begin
      destsite = wait.until{driver.find_element(:xpath,"/html/body/div[1]/a")}
      # destsite = driver.find_element(:xpath,"/html/body/div[1]/a")
      Log.WriteInfo("find Skip to website editor")
    rescue
      Log.WriteError("not find Skip to website editor")
      mozelloAccount.errorreason = "not find Skip to website editor" + '`' +mozelloAccount.errorreason
      destsite = nil
    end
    if(destsite!=nil)
      destsite.click
    end
    wait = Selenium::WebDriver::Wait.new(:timeout=>@waittime,:interval=>1)
    wait.until{driver.find_element(:xpath,"/html/body/div[4]/div[1]/div")}

    Log.WriteInfo("-----------------------Register Process End----------------------")
    return rtn
  rescue
    Log.WriteInfo("Register failed!error:#{$!} at:#{$@}")
    mozelloAccount.errorreason = "Register failed! 用户被注册或浏览器被关闭，超时" + '`' +mozelloAccount.errorreason 
    Log.WriteInfo("---------------Register Process end----------------")
    Browser.SaveImage(driver,mozelloAccount.account)
    return false
  end
end
# sleep 2
# 登陆类
class MozelloLogin
  def initialize(loginconfig)
    @loginconfig = loginconfig
  end
  def VerifConfig
    begin
      if(@loginconfig!=nil)
        @waittime = 10
        if(@loginconfig["waittime"])
          @waittime = @loginconfig["waittime"].to_i
        end
        if(@loginconfig["loginfile"]==nil or @loginconfig["loginfile"]=="")
          Log.WriteError("MozelloLoginAccount Not Defend")
          return false
        end
        @retrylogin = 1
        if(@loginconfig["retrylogin"]!=nil and @loginconfig["retrylogin"]!="")
          @retrylogin = @loginconfig["retrylogin"].to_i + 1
        end
        @retrysleep = 2
        if(@loginconfig["retrysleep"]!=nil and @loginconfig["retrysleep"]!="")
          @retrysleep = @loginconfig["retrysleep"].to_i
        end
        @retrytime = 0
        if(@loginconfig["retrytime"]!=nil and @loginconfig["retrytime"]!="")
          @retrytime = @loginconfig["retrytime"].to_i
        end
        return true
      else
        Log.WriteError("MozelloLogin Config Is Nil")
        return false
      end
    rescue
      Log.WriteError("MozelloLogin Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

  def Operate(driver,mozelloAccount)
    rtn = true
    trytimes = 0
    trylogin = @retrylogin
    Log.WriteInfo("-----------------------do Login Process----------------------")
    begin
      while trylogin>0 do
        mozelloAccount.errorreason = ""
        begin
          driver.get "http://www.mozello.com/session/login/"
          Log.WriteInfo("get http://www.mozello.com/session/login/ ok!")
        rescue
          Log.WriteError("get http://www.mozello.com/session/login/ failed!")
          mozelloAccount.errorreason = "get http://www.mozello.com/session/login/ failed!"
        end
        # wait = Selenium::WebDriver::Wait.new(:timeout=>@waittime,:interval=>1)
        # wait.until{driver.find_element(:xpath,".//*[@id='wp-submit']")}

        begin
          destsite = driver.find_element(:xpath,"/html/body/div[1]/form/div[1]/input")
          Log.WriteInfo("发现账户名输入框")
        rescue
          Log.WriteError("没有发现帐户名输入框")
          mozelloAccount.errorreason = "没有发现帐户名输入框" + '`' + mozelloAccount.errorreason
          destsite = nil
        end
        if(destsite!=nil)
          destsite.send_keys(mozelloAccount.account)
        end
        begin
          destsite = driver.find_element(:xpath,"/html/body/div[1]/form/div[2]/input")
          Log.WriteInfo("发现密码输入框")
        rescue
          Log.WriteError("没有密码输入框")
          mozelloAccount.errorreason = "没有密码输入框" + '`' + mozelloAccount.errorreason
          destsite = nil
        end
        if(destsite!=nil)
          destsite.send_keys(mozelloAccount.password)
        end
        begin
          destsite = driver.find_element(:xpath,"/html/body/div[1]/form/ul/li/input")
          Log.WriteInfo("发现登录按钮")
        rescue
          Log.WriteError("没有发现登录按钮")
          mozelloAccount.errorreason = "没有发现登录按钮" + '`' + mozelloAccount.errorreason
          destsite = nil
        end
        if(destsite!=nil)
          destsite.click
        end
        wait = Selenium::WebDriver::Wait.new(:timeout=>@waittime,:interval=>1)
        begin
          sleep 2
          destsite = wait.until{driver.find_element(:xpath,"/html/body/div[1]/h1")}
          Log.WriteInfo("Login Success.")
          trylogin = 0
        rescue
          Log.WriteError("Login failed.")
          trylogin = trylogin-1
          if(trylogin<=0)
            mozelloAccount.errorreason = "Login failed!账号不存在或者已封禁" + '`' +mozelloAccount.errorreason
            # Browser.SaveImage(driver,mozelloAccount.account)
            rtn=false
          else
            sleep @retrysleep
          end
        end
      end
      Log.WriteInfo("-----------*****Login Process end*****-------------")
      return rtn
    rescue
      if(trytimes<@retrytime)
        trytimes=trytimes+1
        sleep @retrysleep
        retry
      end
      Log.WriteError("Login failed!error:#{$!} at:#{$@}")
      Log.WriteInfo("---------------EmailConfirm Process End----------------")
      # Browser.SaveImage(driver,mozelloAccount.account)
      return false
    end
  end
end

#####邮箱验证
class MozelloEmailConfirm
  def initialize(emailconfirmconfig)
    @emailconfirmconfig = emailconfirmconfig
  end

  def VerifConfig
    begin
      if(@emailconfirmconfig!=nil)
        if(@emailconfirmconfig["url"]==nil or @emailconfirmconfig["url"]=="")
          Log.WriteError("MozelloEmailConfirm Url Not Defend")
          return false
        end
        @url = @emailconfirmconfig["url"]
        @retrytime = 1
        @retrysleep = 30
        @retrysendEmail = 1
        if(@emailconfirmconfig["retrytime"]!=nil and @emailconfirmconfig["retrytime"]!="")
          @retrytime = @emailconfirmconfig["retrytime"].to_i
        end
        if(@emailconfirmconfig["retrysleep"]!=nil and @emailconfirmconfig["retrysleep"]!="")
          @retrysleep = @emailconfirmconfig["retrysleep"].to_i
        end
        if(@emailconfirmconfig["retrysendEmail"]!=nil and @emailconfirmconfig["retrysendEmail"]!="")
        	@retrysendEmail = @emailconfirmconfig["retrysendEmail"].to_i
        end
        return true
      else
        Log.WriteError("MozelloEmailConfirm Config Is Nil")
        return false
      end
    rescue
      Log.WriteError("MozelloEmailConfirm Config Verification Failed!error:#{$!} at:#{$@}")
      return false
    end
  end

  def Operate(driver,mozelloAccount)
    trytimes=0
    begin
      trysends=0
      rtn=true
      mozelloAccount.errorreason = ""
      Log.WriteInfo("---------------do EmailConfirm Process----------------")
      begin
      	####获取服务器的验证链接，如http://45.42.84.154:12315/zp-work/URL/Indulgy/4rgHtPPP5@p.tiger51.com.txt,里面内容为一串链接
      	url = @url + mozelloAccount.account + ".txt"
      	agent = Mechanize.new
      	page = agent.get(url)
      rescue
        mozelloAccount.errorreason = ""
      	Log.WriteInfo("服务器没有激活邮件")
        mozelloAccount.errorreason = "服务器没有激活邮件"
      	if(trysends<@retrysendEmail)
      		trysends=trysends+1
          	puts "#{trysends}"
	      	begin
            mozelloAccount.errorreason = ""
	      		driver.get('https://mozello.com/me/next/welcome')
	      		destsite = driver.find_element(:xpath,".//*[@id='content']/div[1]/span/div/p[3]/button[1]")
	      		Log.WriteInfo("重新发送激活电子邮件")
	      	rescue
	      		Log.WriteError("没有找到发送激活电子邮件链接")
            	mozelloAccount.errorreason = "没有找到发送激活电子邮件链接"
	      		destsite = nil
	      	end
	      	if(destsite!=nil)
	      		destsite.click
	      	end
	      	sleep @retrysleep
        retry
      	end
      end

      begin
      	url = page.body.chomp   #.chomp从字符串末尾移除记录分隔符（$/），通常是 \n。如果没有记录分隔符，则不进行任何操作。
        driver.get(url)
        Log.WriteInfo("get #{url} ok!")
      rescue
        Log.WriteError("get #{url} failed!")
        mozelloAccount.errorreason = "get #{url} failed!" + '`' +mozelloAccount.errorreason+"服务器没有激活邮件"
      end
      begin
        destsite = driver.find_element(:xpath,".//*[@id='secondary']/div/ul/div/div[1]/a")
        Log.WriteInfo("EmailConfirm Success.")
      rescue
        Log.WriteError("EmailConfirm failed.")
        mozelloAccount.errorreason = "EmailConfirm failed!" + '`' +mozelloAccount.errorreason
        Browser.SaveImage(driver,mozelloAccount.account)
        rtn=false
      end
      Log.WriteInfo("-----------*****EmailConfirm Process end*****-------------")
      return rtn
    rescue
      if(trytimes<@retrytime)
        trytimes=trytimes+1
        sleep @retrysleep
        retry
      end
      Log.WriteError("EmailConfirm failed!error:#{$!} at:#{$@}")
      mozelloAccount.errorreason = "EmailConfirm failed! 浏览器关闭或超时，程序终止" + '`' +mozelloAccount.errorreason
      Log.WriteInfo("---------------EmailConfirm Process end----------------")
      Browser.SaveImage(driver,mozelloAccount.account)
      return false
    end
  end
end

class Mozello
  def initialize(mozelloconfig,browser)
    @mozelloconfig = mozelloconfig
    @browser = browser
  end

  def VerifConfig
    begin
      if(@mozelloconfig==nil or @mozelloconfig=="")
        Log.WriteError("Mozello Config Not Exists.")
        return false
      end
      ##########验证config下mozello下的account
      @mozelloAccounts = MozelloAccounts.new(@mozelloconfig["accounts"])
      if(!@mozelloAccounts.VerifConfig)
        return false
      end

      @operates = {}
  #####mozelloconfig-->>config下mozello 下regedit，Emailconfirm，login分别进行验证并操作  ############
      for i in 0..@mozelloconfig.length-1
#########################################当要执行登录操作时，重新分配账号####################
        if(@mozelloconfig.keys[i]=="login")
          @mozelloAccounts = MozelloLoginAccounts.new(@mozelloconfig["login"],@mozelloconfig["accounts"])
          if(!@mozelloAccounts.VerifConfig)
            return false
          end
        end
        if(!CreateOperateAndVerif(@mozelloconfig.keys[i],@mozelloconfig.values[i],@operates))
          return false
        end
      end

      return true
    rescue
      return false
    end
  end

  def Operate
    begin
      driver = nil
      while true
        Log.WriteInfo("Get A Account")
        if(!@mozelloAccounts.ReadAccount)
          return
        end
        begin
          puts @mozelloAccounts.CurrentAccount
          Log.WriteInfo("Create A Driver")
          driver = @browser.DriverCreate(@mozelloAccounts.CurrentAccount.proxy,@mozelloAccounts.CurrentAccount.useragent)
          if(driver == nil)
            return
          end
          while(true)
            if(Browser.CheckProxyEnable(driver,"https://www.baidu.com/","#kw"))
            # if(Browser.CheckProxyEnable(driver,"https://zh-cn.mozello.com/","#top-create-website-button"))
              isSuccess = true
              @mozelloAccounts.CurrentAccount.startTime = Time.new.strftime("%Y-%m-%d %H:%M:%S")
              @mozelloAccounts.CurrentAccount.proxy = @browser.proxyCurrentUse
              @mozelloAccounts.CurrentAccount.useragent = @browser.useragentCurrentUse
              for i in 0..@operates.length-1
                @mozelloAccounts.CurrentAccount.errorstep = @operates.keys[i]
                if(!@operates.values[i].Operate(driver,@mozelloAccounts.CurrentAccount))
                  isSuccess = false
                  break
                end
              end
              @mozelloAccounts.CurrentAccount.endTime = Time.new.strftime("%Y-%m-%d %H:%M:%S")
              @mozelloAccounts.CurrentAccount.issuccess= isSuccess
              break
            else
              Browser.SaveImage(driver,@mozelloAccounts.CurrentAccount.account)
              if(@mozelloAccounts.CurrentAccount.proxy ==nil and @mozelloAccounts.CurrentAccount.useragent == nil)
                Log.WriteInfo("Create A Driver")
                driver = @browser.DriverCreate(@mozelloAccounts.CurrentAccount.proxy,@mozelloAccounts.CurrentAccount.useragent)
              else
                break
              end
            end
          end
        rescue
          Log.WriteError("Operate Failed!error:#{$!} at:#{$@}")
          @mozelloAccounts.CurrentAccount.errorreason = "Operate Failed!" + @mozelloAccounts.CurrentAccount.errorreason
        end
        begin
          if(driver!=nil)
            driver.close
            # driver.quit
            driver=nil
          end
        rescue
        end
        @mozelloAccounts.WriteResult
        sleepTime = @mozelloAccounts.GetSleepTime
        Log.WriteInfo("Sleep #{sleepTime} S")
        sleep sleepTime
      end
      #rescue Interrupt
      # begin
      #   if(driver!=nil)
      #     driver.close
      #     driver.quit
      #     driver=nil
      #   end
      # rescue
      # end
    end
  rescue
    Log.WriteError("Operate Failed!error:#{$!} at:#{$@}")
  end

  private

#################各个功能分类操作##
  def CreateOperateAndVerif(key,config,operates)
    operate = nil
    case key
    when "register"
      operate =MozelloRegister.new(config)
    when "login"
      operate =MozelloLogin.new(config)
    when "emailconfirm"
      operate = MozelloEmailConfirm.new(config)
    when "collect"
      operate = MozelloCollect.new(config)
    when "follow"
      operate = MozelloFollow.new(config)
    when "imageupdate"
      operate = MozelloImageUpdate.new(config)
    end
    if(operate!=nil)
      if(!operate.VerifConfig)
        return false
      end
      operates[key] = operate
    end
    return true
  rescue
    return false
  end
end