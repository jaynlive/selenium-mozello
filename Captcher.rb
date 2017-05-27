require 'net/http'
require 'selenium-webdriver'
require 'base64'

class DeCaptcher
    @url = 'http://poster.de-captcher.com'
    @login = 'zcm3108'
    @password = '07765752q'
    @print_format = 'line'
    def DeCaptcher.getResult(picType)
      ###显示余额
      uri = URI(@url)
      balance = Net::HTTP.post_form(uri,{
          'function'      => 'balance',
          'username'      => @login,
          'password'      => @password,
      })
      puts '账户剩余：'+balance.body
      # puts balance.message
      resultpath = "#{File.dirname(__FILE__)}/reCaptcher"
      if(!File.exist?(resultpath))
          puts "not exist reCaptcher"
      end
      trytime = 1
      if(picType=="select_not_example_pic" or picType=="select_exist_example_pic")
        begin
          pic_type = 82
          post = {
              'function'      => 'picture2',
              'username'      => @login,
              'password'      => @password,

          }
          # if(picType=="select_exist_example_pic")
          #   ###样例图片
          #   example_picfile = File.open("#{resultpath}/example_pic.jpg",'rb')
          #   example_pic = example_picfile.read
          #   post['example_pict1'] = example_pic
          #   example_picfile.close
          # end

          ###待判断图片
          for i in 1..9
            picfile = File.open("#{resultpath}/"+i.to_s+".jpg",'rb')
            pic = picfile.read
            post['pict'+i.to_s] = pic
            picfile.close
          end
          post['pict10'] = File.open("#{resultpath}/1.jpg",'rb').read
          ###问题描述
          questionfile = File.open("#{resultpath}/question.txt",'rb')
          question = questionfile.read
          post['text1'] = question
          questionfile.close

          post['pict_to'] = "0"
          post['pict_type'] = pic_type
          post['print_format'] = @print_format

          uri = URI(@url)
          (0..0).each do |temp|
            res = Net::HTTP.post_form(uri,post)
            puts res.body
            result = res.body.split('|')
            ###显示余额
            balance = Net::HTTP.post_form(uri,{
                'function'      => 'balance',
                'username'      => @login,
                'password'      => @password,
            })
            puts '处理完后账户剩余：'+balance.body
            # puts balance.message
            if(result[0]!='0' and result[1]!=nil and result[2]!=nil)
              DeCaptcher.compensation(result[1],result[2])
              puts '索赔处理完'
              return nil
            end
            redo if(result[0]!='0')
            return result
          end
          #######return result不能放这里，会提示没有改变量。result生成期在each里
        rescue
          puts "error:#{$!} at:#{$@}"
        end
      elsif(picType=="input")
        begin
          pic_type = 0
          post = {
              'function'      => 'picture2',
              'username'      => @login,
              'password'      => @password,
          }
          f = File.open('#{resultpath}/captcha_pic.jpg','rb')
          genpic = f.read
          f.close
          post['pict'] = genpic
          post['pict_to'] = "0"
          post['pict_type'] = pic_type
          post['print_format'] = @print_format

          uri = URI(@url)
          (0..0).each do |temp|
            res = Net::HTTP.post_form(uri,post)
            puts res.body
            result = res.body.split('|')
            ###返回结果格式ResultCode|MajorID|MinorID|Type|Timeout|Text
            if(result[0]!='0' and result[1].length>0 and result[2].length>0)
              DeCaptcher.compensation(result[1],result[2])
              puts '索赔处理完'
              return nil
            end
            redo if(result[0]!='0')
          end
          return result
        rescue
          puts "error:#{$!} at:#{$@}"
        end
      else
        puts "not this decaptche type!"
      end
    end
    #####对识别质量较差的图片进行索赔
    def DeCaptcher.compensation(majorID,minorID)
      puts '发起索赔......'
      post = {
          'function'      => 'picture_bad2',
          'username'      => @login,
          'password'      => @password,
      }
      post["major_id"] = majorID
      post["minor_id"] = minorID
      uri = URI(@url)
      res = Net::HTTP.post_form(uri,post)
      puts res.body + res.message
      ###显示余额
      # uri = URI(@url)
      balance = Net::HTTP.post_form(uri,{
          'function'      => 'balance',
          'username'      => @login,
          'password'      => @password,
      })
      puts '索赔后账户剩余：'+balance.body
      # puts balance.message
    end
end

class ReCaptcher
  def ReCaptcher.getCaptcha(driver)
    resultpath = "#{File.dirname(__FILE__)}/reCaptcher"
    if(!File.exist?(resultpath))
        Dir.mkdir(resultpath)
    end
    begin
      #############九宫格型
      if(driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[1]"))
        #####问题描述
        begin
          imagetype = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[1]/div[1]/div[1]")
          ####带样图的文本
          if(imagetype.attribute("class")=="rc-imageselect-candidates")
            ####不带样图的文本 
            bodyText = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[1]/div[1]/div[2]/strong")
            File.open("#{resultpath}/question.txt","w+") do |file|
              file.write(bodyText.text)
            end
          elsif(imagetype.attribute("class")=="rc-imageselect-desc-no-canonical")
            bodyText = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[1]/div[1]/div[1]/strong")
            File.open("#{resultpath}/question.txt","w+") do |file|
              file.write(bodyText.text)
            end
          else
            puts "没有获取到问题描述"
          end
        rescue
          puts "#{$!},#{$@}"
        end
        ######待选图片
        begin
          ####获得让选择的大图(300*300piex)
          select_pic = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[2]/div[1]/table/tbody/tr[1]/td[1]/div[1]/div/img")
          picslink = select_pic.attribute("src")
          data=open(picslink){|f|f.read}
          open("#{resultpath}/select_pic.jpg","w+"){|f|f.write(data)}
          ###将图片分成9张(100*100piex)
          x = 1
          0.upto(2) do |h|
            h = 100*h
            0.upto(2) do |w|
              img = MiniMagick::Image.open("#{resultpath}/select_pic.jpg")
              # img.format('jpg')
              # img.quality('95')
              w = 100*w
              img.crop("100x100+#{w}+#{h}")
              img.write("#{resultpath}/#{x}.jpg")
              x += 1
            end
          end
        rescue
          puts '待选图片出错'
          puts "#{$!},#{$@}"
        end
        ####样列图片
        begin
          example = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[1]/div[1]/div[1]/img")
          example_pic = example.attribute("src").split(',')[1]
          File.open("#{resultpath}/example_pic.jpg","w+") do |file|
            file.write(Base64.decode64(example_pic))
          end
        rescue
          reCaptchaType = 'select_not_example_pic'
          return reCaptchaType
        end
        reCaptchaType = 'select_exist_example_pic'
        return reCaptchaType
      end
    rescue
    ##########输入型
      begin
        if(driver.find_element(:xpath,"/html/body/div[1]/div/div[1]"))
          begin
            captcha_pic = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/img")
            picslink = captcha_pic.attribute("src")
            data=open(picslink){|f|f.read}
            open("#{resultpath}/captcha_pic.jpg","w+"){|f|f.write(data)}
          rescue
            puts "error:#{$!} at:#{$@}"
          end
          begin
            input = driver.find_element(:xpath,"/html/body/div[1]/div/div[1]/input")
            input.send_key("")
          rescue
            puts "error:#{$!} at:#{$@}"
          end
          reCaptchaType = 'input'
          return reCaptchaType
        else
          puts "not reCaptcha!!!"
          return nil
        end
      end
    end
  end

  def ReCaptcher.verify(driver,result,reCaptchaType)
    ###选择类型
    if(reCaptchaType=="select_not_example_pic" or reCaptchaType=="select_exist_example_pic")
      begin
        result = result.split(' ')
        ########去掉第10张重复的
        for i in 0...result.length-1
          if(result[i]=='1')
            select = driver.find_element(:xpath,"/html/body/div[1]/div/div[2]/div[2]/div[1]/table/tbody/tr[#{i/3+1}]/td[#{i%3+1}]/div[1]/div")
            select.click
          end
        end
        verify = driver.find_element(:xpath,"/html/body/div[1]/div/div[3]/div[2]/div[1]/div[2]/div")
        verify.click
      end
    elsif(reCaptchaType=='input')
      begin
        input = driver.find_element(:xpath,"/html/body/div[1]/div/div[1]/input")
        input.send_key(result)
        verify = driver.find_element(:xpath,"/html/body/div[1]/div/div[3]/div[2]/div[1]/div[2]/div")
        verify.click
      end 
    end
  end
end