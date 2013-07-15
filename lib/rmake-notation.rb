# encoding: utf-8

require "rmake-util"
require "rmake-notation/version"

module Rmake::Notation
  DOMAIN = "rmake.jp"
  
  def generate_contents(content)
    @title_list ||= []
    
    result = ''
    blocks = self.to_blocks(content)
    
    blocks.each do |b|
      block = self.block_to_html(b)
      result += block
    end
    
    #result += " ********** " +  blocks.join(",")
    result.gsub("-)", "]")
    
  rescue => err
    message = err.message + "\n"
    message += err.backtrace.join("\n")
    message += "文章にエラーもしくは不正な文字が含まれているようです。確認してください。"
  end
  
  def title_list
    @title_list
  end
  
  def reflesh_title_list
    @title_list = []
  end
  
  def add_plugin(plugin)
    @plugins ||= []
    
    if (plugin.respond_to?(:target?) && plugin.respond_to?(:execute))
      @plugins << plugin
      true
    else
      false
    end
  end

  def to_blocks(content)
    contents = Array.new
    # content.gsub(/(^[|].*?(\n)[^|])|(^[-].*?(?=((^[^-])|\z)))|(^[{][{][{].*?[}][}][}])|(^[\[].*?[\]])|(^[!]*.*?$)|(^http[:][\/][\/])|(?!^).*?$/m) {|s|
    content.gsub(/(^[|][|][|].*?[|][|][|])|(^[|].*?(?=(^[^|]|\z)))|(^[-].*?(?=((^[^-])|\z)))|(^[{][{][{].*?[}][}][}])|([\[].*?[\]])|(^[!]*.*?$)|(^http[:][\/][\/])|(^https[:][\/][\/])|(?!^).*?$/m) {|s|
      contents << s
    }
    contents
  end
  
  def process_table_line(block)
    header = true
    style = ""
    tag = "td style=\"#{style}\""
    code_reg = /[{][{][{].*?[}][}][}]/m
    
    pcodes = []
    block_text = block
    pcode_count = 0
    while block_text.index(code_reg)
      pcodes << self.generate_contents(block_text.slice(code_reg))
      block_text = block_text.sub(code_reg, "___dummy_pcodes___")
      
      pcode_count += 1
    end
    
    s_arr = block_text.split("\n")
    s = ""
    line_index = 0
    temp_item = ""
    
    s_arr.each do |item|
      temp_item += item

      if item.index("|||") == 0
        temp_item = ""
        if item.index("header:none")
          header = false
        end
        
      elsif temp_item.rindex(/[|]/).to_i == temp_item.length - 2
        item = temp_item
        
        if line_index == 0 && header
          tag = "th style=\"#{style}\""
        end

        item = "<tr><#{tag}>" + item[item.index('|') + 1..item.rindex('|') - 1] + "</#{tag}></tr>"

        items_before = item.split('|')
        items_after = []
        items_before.each do |before|
          items_after << self.generate_contents(before).gsub("<br />", "")
        end

        s += items_after.join("</#{tag}><#{tag}>")
        
        line_index += 1
        temp_item = ""
        tag = "td style=\"#{style}\""
      end

    end
    
    pcodes.each do |pcode|
      s = s.sub("___dummy_pcodes___", pcode)
    end
    
    block = "<table class=\"table\">#{s}</table>"
  end
  
  def block_to_html(block)
    case block
    when /\A[\[]/
      parsed_block = self.parse_inline(block)
      block = self.inline_to_html(parsed_block)
    when /(\A[{][{][{])/
      parsed_block = self.parse_inline(block.gsub("{{{", "[").gsub("}}}", "]"))
      block = self.inline_to_html(parsed_block)
    when /^[!]/
      len = block.length - block.gsub!(/^[!]*/, "").length + 2
      s = generate_contents(block)
      a_name = "#{@title_list.length + 1}_#{len}"
      @title_list << [s, len, a_name]
      block = "<h#{len} id=\"#{a_name}\"><a name=\"title_#{a_name}\"></a>#{s}</h#{len}>"

    when /^[|][|][|]/
      block = self.process_table_line(block)
      
    when /^[|]/
      s_arr = block.split("\n")
      #s_arr.pop
      s = ""
      line_index = 0
      s_arr.each do |item|
        if line_index == 0
          item = '<tr><th>' + item[item.index('|') + 1..item.rindex('|') - 1] + '</th></tr>'
          s += item.split('|').join('</th><th>')
        else
          item = '<tr><td>' + item[item.index('|') + 1..item.rindex('|') - 1] + '</td></tr>'
          s += item.split('|').join('</td><td>')
        end

        line_index += 1
      end
      block = "<table class=\"table\">#{s}</table>"
      
    when /^[-]/
      block = list(block.split("\n"))

    when /^http[:][\/][\/]/
      block = "<a href='#{block}'>#{block}</a><br />"
      
    when /^https[:][\/][\/]/
      block = "<a href='#{block}'>#{block}</a><br />"
      
    else
      block = self.inline_to_html_from_block(block)
      block = block + "<br />" unless block == ""
    end
    
    block
  end
  
  def list(s_arr)
    s_arr << ""
    list_arr = []
    s = ""
    s_arr.each do |item|
      if item.length > 0 && item.index("--") == 0
        list_arr << item[1..item.length-1]
      elsif item.length > 0 && item.index("-") == 0
        if list_arr.length > 0
          child_list = list(list_arr)
          list_arr = []
        else
          child_list = ""
        end
        
        line = generate_contents(item[1..item.length])
        if !child_list.blank?
          s += "#{child_list}</li><li>#{line}" 
        else
          s += "<li>#{line}" 
        end
        
      else
        if list_arr.length > 0
          child_list = list(list_arr)
          s += "#{child_list}"
        end
      end
    end
    s = s + "</li>" if !s.blank?
    s = generate_contents(s)
    "<ul class=\"wikiUl\">#{s}</ul>".gsub('<br />', '')
  end
  
  def inline_to_html(parsed_block)
    command = parsed_block[0]
    result = ''

    case command
    when 'link'
      link = parsed_block[1]
      title = parsed_block[1]
      if parsed_block.length > 2
        title = parsed_block[2..parsed_block.length-1].join(" ")
      end
      
      result = "<a href='" + link + "'>" + title + "</a>"
    when "code"
      text = parsed_block[1..parsed_block.length-1].join(" ")
      result = "<div style=\"margin: 0 1em;\"><pre class=\"prettyprint\">" + text + "</pre></div>"
      #p parsed_block
    when "pcode"
      text = parsed_block[1..parsed_block.length-1].join(" ")
      result = "<div style=\"margin: 0 1em;\"><pre style=\"font-family:sans-serif;\" class=\"prettyprint\">" + text + "</pre></div>"
    when "b"
      url = parsed_block[1]
      quote = parsed_block[2..parsed_block.length-1].join(" ")
      result = "<div class='blockquote'><blockquote cite='#{url}'><p class='bq'>#{quote}</p><cite><a href='#{url}'>#{url}</a></cite></blockquote></div>"
    when "image_url"
      url = parsed_block[1]
      result = "<img src=\"#{url}\" />"

    when "game"
      id = parsed_block[1]
      text = parsed_block[2] ? parsed_block[2..parsed_block.length-1] : nil
      text = text ? text.join(" ") : "ゲーム[ID:#{id}]"
      url = "http://#{DOMAIN}/games/#{id}/play"
      result = "<a href=\"#{url}\" title=\"#{text}\">#{text}</a>"
      
    when "open_game_form"
      id = parsed_block[1]
      text = parsed_block[2] ? parsed_block[2] : nil
      submit_label = parsed_block[3] ? parsed_block[3..parsed_block.length-1] : nil
      if text.blank?
        text = "パラメータ"
      end
      
      if submit_label.blank?
        submit_label = "ゲームを開く"
      end
      url = "http://#{DOMAIN}/games/#{id}/play"
      result = <<-EOS
<form method="get" action="#{url}">
    #{text}
    <input type="text" name="gd" maxlength="200" size=20 />
    <input type="submit" value="#{submit_label}" />
</form>
EOS
      
      
    when "item"
      id = parsed_block[1]
      text = parsed_block[2] ? parsed_block[2..parsed_block.length-1] : nil
      text = text ? text.join(" ") : "素材/ゲームデータ[ID:#{id}]"
      url = "http://#{DOMAIN}/published_items/#{id}"
      result = "<a href=\"#{url}\" title=\"#{text}\">#{text}</a>"
      
    when "wiki"
      text = parsed_block[1..parsed_block.length-1].join(" ")
      url = "http://page.#{DOMAIN}/a/" + text
      result = "<a href=\"#{url}\" title=\"#{text}\">#{text}</a>"

    when "jump_target"
      text = parsed_block[1] ? parsed_block[1..parsed_block.length-1] : nil
      result = "<a name=\"#{text.join}\"></a>"
      
    when "jump"
      link = parsed_block[1]
      title = parsed_block[1]
      if parsed_block.length > 2
        title = parsed_block[2..parsed_block.length-1].join(" ")
      end
      
      result = "<a href=\"##{link}\">" + title + "</a>"
      
    when "strike"
      text = parsed_block[1] ? parsed_block[1..parsed_block.length-1] : nil
      result = "<span style=\"text-decoration:line-through;\">#{text}</span>"

    when "bold"
      text = parsed_block[1] ? parsed_block[1..parsed_block.length-1] : nil
      result = "<span style=\"font-weight:bold;\">#{text}</span>"

    when "memo"
      result = ""

    when "font"
      tags = parsed_block[1] ? parsed_block[1].split("_") : []
      style = ""
      tags.each do |tag|
        if tag == "bold"
          style += "font-weight:bold;"
        elsif tag == "italic"
          style += "font-style: italic;"
        elsif tag == "strike"
          style += "text-decoration:line-through;"
        elsif ["xx-small", "x-small", "small", "medium", "large", "x-large", "xx-large"].include?(tag)
          style += "font-size:#{tag};"
        else
          style += "color:#{tag};"
        end
      end
      
      text = parsed_block[2] ? parsed_block[2..parsed_block.length-1] : nil
      result = "<span style=\"#{style}\">#{text}</span>"

    when "nicovideo"
      id = parsed_block[1]
      result = <<-EOS
<script type="text/javascript" src="http://ext.nicovideo.jp/thumb_watch/#{id}?w=490&h=307"></script>
<noscript>JavaScriptが動いていないため、動画埋め込みが動作していません。</noscript>
      EOS

    when "youtube"
      id = parsed_block[1]
      result = <<-EOS
<iframe width="425" height="349" src="http://www.youtube.com/embed/#{id}"
  frameborder="0" allowfullscreen></iframe>
      EOS

    when "game_player"
      id = parsed_block[1]
      @wiki_module_game_embed ||= false
      unless @wiki_module_game_embed
        result = "<script charset=\"utf-8\" src=\"http://rmake.jp/gadget/#{id.to_i}/js\"></script>"
        @wiki_module_game_embed = true
      else
        text = parsed_block[2] ? parsed_block[2..parsed_block.length-1] : nil
        text = text ? text.join(" ") : "ゲーム[ID:#{id}]"
        url = "http://#{DOMAIN}/games/#{id}/play"
        result = "<a href=\"#{url}\" title=\"#{text}\">#{text}</a>"
      end
      
    else
      
      result = execute_plugins(command, parsed_block)
      if result
        
      else
        result = "[" + parsed_block.join(" ") + "]"
      end
    end
    
    result
  rescue => err
    "<div style=\"color:red;font-weight:bold;\">記述に間違いがあります: [" + parsed_block.join(" ") + "]</div>"
  end
  
  def execute_plugins(command, parsed_block)
    result = false
    
    @plugins ||= []
    @plugins.each do |plugin|
      if plugin.target?(command)
        result = plugin.execute(command, parsed_block)
        break
      end
    end
    
    result
  rescue => err
    parsed_block << "{{プラグインのエラー}}"
  end
  
  def inline_to_html_from_block(block)
    block.gsub!(/[\[].*?[\]]/) {|s|
      s = self.inline_to_html(self.parse_inline(s))
    }
    
    block
  end
  
  def parse_inline(content)
    content[1..content.length-2].sub(/([ ]|\n|\r\n|\r)/, " ").split(/[ ]/)
  end

end
