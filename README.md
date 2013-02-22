rmake-notation
==============

Rmakeで利用しているWiki記法「Rmake記法」を実現するためのgemです。

- [ゲームを作成して共有するサイト - Rmake](http://rmake.jp/)
- [Rmake記法の紹介とデモサイトはこちら](http://rmake-notation.herokuapp.com/)
- [サンプルアプリのリポジトリはこちらです](https://github.com/akasata/rmake-notation-samples)

## SYSTEM REQUIREMENTS

- Ruby 1.9.3+

Windows環境の方は以下のパッケージを利用するといいでしょう。

- [ActiveScriptRuby and Other packages](http://www.artonx.org/data/asr/)

## INSTALLATION

Gemをインストールして使ってください。

    $ gem install rmake-notation

Railsで使う際は、controllerに以下のように記述しています。helperに定義してもよいでしょう。

    def generate_contents(content)
      @rmake_notation ||= Object.new.extend Rmake::Notation
      @rmake_notation.generate_contents(content)
    end
    
    helper_method :generate_contents

## PLUGIN

Rmake記法はプラグインで拡張することができます。[version]と記述すると、本gemのバージョンを返すプラグインは以下のように記述することができます。

    class VersionPlugin
      def target?(command)
        command == "version"
      end
      
      def execute(command, block)
        Rmake::Notation::VERSION.to_s
      end
    end

    # registration
    @notation = Object.new.extend Rmake::Notation
    @notation.add_plugin(VersionPlugin.new)
    @notation.generate_contents(content)

## LICENSE

MIT License

Copyright (c) 2013 Rmake Developers

## TODO

- specを書く（それに伴いテストしやすい構造に変更する）
- サンプルサイトの例を完全にする
- バグを取る

