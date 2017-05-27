require 'selenium-webdriver'
require 'yaml'

load "#{File.dirname(__FILE__)}/Selenium_Xgrit.rb"
load "#{File.dirname(__FILE__)}/Selenium_Mozello.rb"
load "#{File.dirname(__FILE__)}/Voice_Captcher.rb"
begin
 # Commond :ruby Selenium_Indulgy_Running.rb "indulgy-1/config"
 # if debug
 #   ARGV[0] ="indulgy-1/config"
 # end
 #######运行命令  ruby Selenium_Mozello_Running.rb mozello-1/config
  if(ARGV[0] != nil)      #####  在命令行方法执行ruby文件时，需要从命令行中传入参数，可以使用全局变量：ARGV
    configFile = ARGV[0]  ### ARGV[0] = mozello-1/config
    if(!File.exists?configFile)
      Log.WriteError("Config File #{configFile} Not Exists")
      exit
    end
    config = YAML.load_file(configFile)
    if(config["basepath"]!=nil and config["basepath"]!="")
      Tools.ReplaceConfig(config,"{basepath}",config["basepath"])
    end
    if(config["log"]!=nil&&config["log"]!="")
      Log.LogSetting(config["log"])
    end
    browser = Browser.new(config["browser"])
    if(!browser.VerifConfig)
      exit
    end
    mozello = Mozello.new(config["mozello"],browser)
    if(!mozello.VerifConfig)
      exit
    end
    mozello.Operate
  else
    Log.WriteError("Rigth Commond : Ruby Selenium_Mozello_Running.rb [ConfigFile]")
  end
rescue
  Log.WriteError("error:#{$!} at:#{$@}")
end