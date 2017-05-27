require 'mechanize'
require 'wav-file'
require 'streamio-ffmpeg'

class Sound
  def mp3_to_wav(voicepath)
    movie = FFMPEG::Movie.new("#{voicepath}/audio.mp3")
    opt = {audio_codec: "pcm_s16le", audio_bitrate: 16, audio_sample_rate: 16000,audio_channels: 1}
    movie.transcode("#{voicepath}/test.wav",opt)
  end

  def separate_wav(voicepath)
    format, data = WavFile::read open("#{voicepath}/test.wav")
    ###提取二进制
    bit = 's*' if format.bitPerSample == 16 # int16_t
    bit = 'c*' if format.bitPerSample == 8 # signed char
    wavs = data.data.unpack(bit)
    ####简单去噪
    for i in 0...wavs.length
      if(wavs[i].abs < 25)
        wavs[i] = 0
      end
    end

    length = wavs.length
    thresh = 30  #设置连续为0部分最短数，小于这个数则判定为有效声音的一部分
    output = []
    nozerotemp = []   #二进制非0部分
    i = 0
    while(i<length)
      zeros = []  #二进制连续为0部分
      while(i<length and wavs[i]==0)
        i += 1
        zeros.push(0)
        # zeros << 0   #追加
      end
      if(zeros.length != 0 and zeros.length < thresh)
        nozerotemp += zeros   #将连续无声二进制长度小于thresh添加到有效声音里
      elsif(zeros.length > thresh)
        if(nozerotemp.length >0 and i < length)
          output << nozerotemp   #将有效声音存下来，output此时为二维数组
          nozerotemp = []
        end
      else
        nozerotemp.push(wavs[i])  #将连续不为0的部分存下来
        i += 1
      end
    end
    if(nozerotemp.length > 0)
      output << nozerotemp
    end

    chunks = []
    ####去除有声时间过短的片段
    for i in 0...output.length
      if(output[i].length > 3000)
        chunks << output[i]
      end
    end

    #####音频数据处理
    for i in 0...chunks.length
      chunktemp = []
      chunktemp += chunks[i]

      for k in 0...2000
        chunks[i].unshift(0)
      end

      for k in 0...3000
        chunks[i].push(0)
      end

      # chunks[i] = chunks[i] + chunktemp     #合并两个数组

      # for k in 0...3000
      #   chunks[i].push(0)
      # end

      # chunks[i] += chunks[i]
      # wavs = chunks[i]
      # wavs_mono = wavs.dup   #Ruby内置的方法Object#clone和Object#dup可以用来copy一个对象，两者区别是dup只复制对象的内容，而clone还复制与对象相关联的内容
      # puts wavs_mono
      # puts chunks.to_i
      # File.open("num#{i}", "w"){|out|
      #   out.write(chunks[i])
      # }
      data.data = chunks[i].pack(bit)
      open("#{voicepath}/sound#{i}.wav", "w"){|out|
        WavFile::write(out, format, [data])
      }
    end
    return chunks.length
  end
end

class Tools
  ####替换路径
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
    puts 'error!'
  end
  #######一层确定
  def Tools.sure(getresult)
    out = ''
    for text in getresult
      if(text.include?('zero'))
        out = '0'
        break()
      elsif(text.include?('one'))
        out = '1'
        break()
      elsif(text.include?('two'))
        out = '2'
        break()
      elsif(text.include?('three'))
        out = '3'
        break()
      elsif(text.include?('four'))
        out = '4'
        break()
      elsif(text.include?('five'))
        out = '5'
        break()
      elsif(text.include?('six'))
        out = '6'
        break()
      elsif(text.include?('seven'))
        out = '7'
        break()
      elsif(text.include?('eight'))
        out = '8'
        break()
      elsif(text.include?('nine'))
        out = '9'
        break()
      # else
      #   out = Tools.analyze(getresult)
      #   if(out != '')
      #     break()
      #   end
      end
    end
    return out
  end
####模糊度高
  def Tools.analyze(getresult)
    for text in getresult
      ###0
      if(text.include?('zero') or /here are all/=~text or /the[re,y] are/=~text or /there will/=~text)
      # if(/ero/=~text)
        out = '0'
        return out
      ###1
      elsif(/one/=~text or /w[a,i,o]n/=~text)
        out = '1'
        return out
      elsif(/too/=~text or /two/=~text or /true/=~text or /through/=~text or /who/=~text)
        out = '2'
        return out
      elsif(/ree/=~text or /freight/=~text)
        out = '3'
        return out
      elsif(/four/=~text or /for/=~text  or /flour/=~text or /work/=~text or /what/=~text)
        out = '4'
        return out
      elsif(/five/=~text or /fire/=~text or /find/=~text or /fly/=~text or /bye/=~text or /fife/=~text or /bu[y,t]/=~text )
        out = '5'
        return out
      elsif(/s[i,e]x/=~text or /sick/=~text or /fax/=~text)
        out = '6'
        return out
      elsif(/seven/=~text)
        out = '7'
        return out
      elsif(/eight/=~text or /IT's/=~text)
        out = '8'
        return out
      elsif(/[n,l]ine/=~text or /the eye/=~text or /night/=~text or /nice/=~text)
        out = '9'
        return out
      else
        out = ''
      end
    end
    return out
  end
######三层选择
  def Tools.select(baidutext,xunfeitext)
    for text in baidutext
      puts "------#{text}-----"
      xunfeitext.each{ |thing|
        case thing
        when 'zero'
          if(text.include?('zero') or /here are all/=~text or /the[re,y] are/=~text or /there will/=~text)
            out = '0'
            return out
          end
        when 'one'
          if(/one/=~text or /w[a,i,o]n/=~text)
            out = '1'
            return out
          end
        when 'two'
          if(/too/=~text or /two/=~text or /true/=~text or /through/=~text or /who/=~text)
            out = '2'
            return out
          end
        when 'three'
          if(/ree/=~text or /freight/=~text)
            out = '3'
            return out
          end
        when 'four'
          if(/four/=~text or /for/=~text  or /flour/=~text or /work/=~text or /what/=~text)
            out = '4'
            return out
          end
        when 'five'
          if(/[f,l]ive/=~text or /fire/=~text or /find/=~text or /fly/=~text or /bye/=~text or /fife/=~text or /bu[y,t]/=~text)
            out = '5'
            return out
          end
        when 'six'
          if(/s[i,e]x/=~text or /sick/=~text or /fax/=~text or /second/=~text)
            out = '6'
            return out
          end
        when 'seven'
          if(/seven/=~text)
            out = '7'
            return out
          end
        when 'eight'
          if(/eight/=~text or /at/=~text)
            out = '8'
            return out
          end
        when 'nine'
          if(/[n,l]ine/=~text or /the eye/=~text)
            out = '9'
            return out
          end
        end
      }
    end
    ##全部待选词没有可匹配
    return 'not match'
  end
end


class STT
  def STT.error(code)
    case code
    when 0
      puts '识别完成'
      return true
    when 3300
      puts '输入参数不正确'
      return false
    when 3301
      puts '识别错误'
      return false
    when 3302
      puts '验证失败'
      return false
    when 3303
      puts '语音服务器后端问题'
      return false
    when 3304
      puts '语音大于60s,超过限额'
      return false
    when 3305
      puts '请求数超过限制，明日再来'
      return false
    else
      puts '未知错误'
      return false
    end
  end

  def voice(file)
    begin
      puts '——————语音识别——————'
      http_header = {
          'Content-Type' => "aaudio/wav; rate=16000",
          'Content-Length' => File.new("#{file}").stat().size
      }
      browser = Mechanize.new
      url = "http://vop.baidu.com/server_api?lan=en&cuid=00-50-56-C0-00-01&token=24.e3f0d124feaf6151e3eeadf201a2834b.2592000.1450246987.282335-7036957"
      soundfile = File.open("#{file}",'rb')
      sound = soundfile.read
      page = browser.post(url,sound,http_header)
    ensure
      soundfile.close
    end
    return page.body.force_encoding('utf-8')
  end

  def speach_to_text(file,xunfeitext=[],sure='false')
    response = voice(file)
    jsoncode = JSON.parse(response)
    result = ''
    if(STT.error(jsoncode['err_no']))
      pp jsoncode['result']  #p可以输出对象形式，puts只输出字符串
      if(!xunfeitext.empty?)
        puts 'Tools.select'
        puts xunfeitext,sure
        result = Tools.select(jsoncode['result'],xunfeitext)
      elsif(sure=='true')
        puts 'Tools.sure'
        result = Tools.sure(jsoncode['result'])
      else
        puts 'Tools.analyze'
        result = Tools.analyze(jsoncode['result'])
      end
      p result
      # name = File.basename(@resoucefile,'.*') #获取翻译文件名称，移除扩展名
      # File.open("#{@resultpath}/#{name}.txt",'wb') do |file|
      #   file.write(jsoncode['result'])
      # end
    end
    return result
  end
end


class XunFeiVoice
  def XunFeiVoice.word(result)
    if(result!= 'fail')
      resultjson = JSON.parse(result)
      jsontemp = resultjson['ws'][0]['cw']
      word = []
      jsontemp.each{|newtemp|
        word.push(XunFeiVoice.number(newtemp['w']))
      }
    end
    return word
  end

  def XunFeiVoice.analyze(result)
    if(result != 'fail')
      resultjson = JSON.parse(result)
      jsontemp = resultjson['ws'][0]['cw']
      # ###去掉非使用自定义词汇的结果
      # jsontemp.map{|newtemp|
      #   if(newtemp['gm']=='0')
      #     jsontemp.delete(newtemp)
      #   end
      # }

      word = ''
      case jsontemp.length
      when 1
        word = XunFeiVoice.number(jsontemp[0]['w'])
      when 2
        ###如果第一个可信度比第二个高出5以上，取第一个结果值
        if(jsontemp[0]['sc'].to_i - jsontemp[1]['sc'].to_i > 5)
          word = XunFeiVoice.number(jsontemp[0]['w'])
        else
          word = [jsontemp[0]['w'],jsontemp[1]['w']]
        end
      when 3
        if(jsontemp[0]['sc'].to_i - jsontemp[1]['sc'].to_i > 5)
          word = XunFeiVoice.number(jsontemp[0]['w'])
        ###第三个可信度与第一个可信度值差距不大于10,且可信度在0.5以上，保留该词
        elsif(jsontemp[0]['sc'].to_i - jsontemp[2]['sc'].to_i < 10 and jsontemp[2]['sc'].to_i > 50)
          word = [jsontemp[0]['w'],jsontemp[1]['w'],jsontemp[2]['w']]
        else
          word = [jsontemp[0]['w'],jsontemp[1]['w']]
        end
      when 4
        if(jsontemp[0]['sc'].to_i - jsontemp[1]['sc'].to_i > 5)
          word = XunFeiVoice.number(jsontemp[0]['w'])
          #第四个可信度与第一个可信度值差距不大于10,且可信度在0.5以上，保留全部词
        elsif(jsontemp[0]['sc'].to_i - jsontemp[3]['sc'].to_i < 10 and jsontemp[2]['sc'].to_i > 50)
          word = [jsontemp[0]['w'],jsontemp[1]['w'],jsontemp[2]['w'],jsontemp[3]['w']]
        ###第三个可信度与第一个可信度值差距不大于10,且可信度在0.5以上，保留该词
        elsif(jsontemp[0]['sc'].to_i - jsontemp[2]['sc'].to_i < 10 and jsontemp[2]['sc'].to_i > 50)
          word = [jsontemp[0]['w'],jsontemp[1]['w'],jsontemp[2]['w']]
        else
          word = [jsontemp[0]['w'],jsontemp[1]['w']]
        end
      else
      end
      return word
    end
  end

  def XunFeiVoice.number(number)
    case number
    when 'zero' 
      number = '0'
    when 'one'
      number = '1' 
    when 'two' 
      number = '2' 
    when 'three' 
      number = '3' 
    when 'four' 
      number = '4' 
    when 'five' 
      number = '5' 
    when 'six' 
      number = '6' 
    when 'seven' 
      number = '7' 
    when 'eight' 
      number = '8' 
    when 'nine' 
      number = '9' 
    end
    return number
  end
end

class HTK
  def HTK.voice(i)
    htkresult = ''
    # soundindex = File.open("/home/sandy/selenium/mozello-1/sound/soundindex.txt").read().to_i
    # for i in 0..soundindex
      system "HCopy -A -D -C #{File.dirname(__FILE__)}/HTK/config/configwav #{File.dirname(__FILE__)}/mozello-1/sound/sound#{i}.wav #{File.dirname(__FILE__)}/HTK/result/sound#{i}.mfcc"
      system "HVite -A -D -T 1 -H #{File.dirname(__FILE__)}/HTK/hmms/allhmms.mmf -i #{File.dirname(__FILE__)}/HTK/result/re.mlf -w #{File.dirname(__FILE__)}/HTK/def/gram.net #{File.dirname(__FILE__)}/HTK/def/dict.txt #{File.dirname(__FILE__)}/HTK/def/hmmlist.txt #{File.dirname(__FILE__)}/HTK/result/sound#{i}.mfcc "
      book = File.open("#{File.dirname(__FILE__)}/HTK/result/re.mlf").read()
      if(book.include?(' zero '))
        htkresult = htkresult + '0'
      elsif(book.include?(' one '))
        htkresult = htkresult + '1'
      elsif(book.include?(' two '))
        htkresult = htkresult + '2'
      elsif(book.include?(' three '))
        htkresult = htkresult + '3'
      elsif(book.include?(' four '))
        htkresult = htkresult + '4'
      elsif(book.include?(' five '))
        htkresult = htkresult + '5'
      elsif(book.include?(' six '))
        htkresult = htkresult + '6'
      elsif(book.include?(' seven '))
        htkresult = htkresult + '7'
      elsif(book.include?(' eight '))
        htkresult = htkresult + '8'
      elsif(book.include?(' nine '))
        htkresult = htkresult + '9'
      end
    # end
    # puts htkresult
    return htkresult
  end
end

class Main
  def Main.start(voicepath)
    begin
      sound = Sound.new
      stt = STT.new
      sound.mp3_to_wav(voicepath)
      # soundindex = sound.separate_wav(voicepath)
      system "python #{File.dirname(__FILE__)}/mozello-1/sound/sound.py"
      ##获取分割文件个数
      soundindex = File.open("#{File.dirname(__FILE__)}/mozello-1/sound/soundindex.txt").read().to_i





      result_all = ''
      #######讯飞
      for i in 0..soundindex
        puts "\n----------------识别sound#{i}.wav---------------"
        ####调用一层可确定
        # puts '第一次识别'
        sureresult = stt.speach_to_text("#{voicepath}/sound#{i}.wav",xunfeitext=[],sure='true')
        if(sureresult!='')
          result_all = result_all + sureresult
          puts sureresult
        else
          system "cp #{voicepath}/sound#{i}.wav #{File.dirname(__FILE__)}/xunfei/bin/wav/test.wav"
          system "#{File.dirname(__FILE__)}/xunfei/bin/asr_sample"  
          
          xunfeijson = File.open("#{File.dirname(__FILE__)}/xunfei/bin/wav/word.txt").read()
          if(xunfeijson!='fail')
            # puts '第二层识别'
            analyzeresult = stt.speach_to_text("#{voicepath}/sound#{i}.wav")
            if(analyzeresult!='' and XunFeiVoice.word(xunfeijson).include?analyzeresult)
              result_all = result_all + analyzeresult
              puts analyzeresult
            else
              xunfeiresult = XunFeiVoice.analyze(xunfeijson)
              if(xunfeiresult.length>1)  #结果长度大于一，说明为数组，识别不确定
                # #####调用百度语音
                # baiduresult = stt.speach_to_text("#{voicepath}/sound#{i}.wav",xunfeitext=xunfeiresult)
                # if(baiduresult == 'not match' or baiduresult=='') #当百度识别没有结果或识别错误时，选择讯飞第一个
                #   result_all = result_all + XunFeiVoice.number(xunfeiresult[0])
                #   puts XunFeiVoice.number(xunfeiresult[0])
                # else
                #   result_all = result_all + baiduresult
                #   puts baiduresult
                # end

                result_all = result_all + HTK.voice(i)
              else
                result_all = result_all + xunfeiresult
                puts xunfeiresult
              end
            end
          else
            puts '************************'
            # baiduresult = stt.speach_to_text("#{voicepath}/sound#{i}.wav")
            # result_all = result_all + baiduresult
            # puts baiduresult
            result_all = result_all + HTK.voice(i)
          end
        end
      end
      puts '————————-------'
      puts result_all

    rescue
      puts "识别过程中出错#{$!}, at:#{$@}"
    end
    return result_all
  end
end