require 'openssl'
require 'base64'
require 'digest'
require 'bcrypt'

def bin2hex(str)
  str.unpack('C*').map{ |b| "%02x" % b }.join('')
end

def hex2bin(str)
  [str].pack "H*"
end

module Jekyll
    module Tags
        class EncryptionTag < IncludeRelativeTag
            def initialize(tag_name, markup, tokens)
                super
                matched = markup.strip.match(VARIABLE_SYNTAX)
                if matched
                  @file = matched["variable"].strip
                  @params = matched["params"].strip
                else
                  @file, @params = markup.strip.split(%r!\s+!, 2)
                end
                validate_params if @params
                @tag_name = tag_name
            end

            def read_file(file, context)
                content = File.read(file, file_read_opts(context))

                params = parse_params(context)

                aes = OpenSSL::Cipher.new('AES-256-CBC')
                aes.encrypt

                salt = params['salt']
                iv = params['iv']

                if iv.nil?
                    iv = aes.random_iv
                end

                if salt.nil?
                    salt = OpenSSL::Random.random_bytes(8)
                end

                context['iv'] = bin2hex(iv)
                context['salt'] = bin2hex(salt)

                aes.key = Digest::SHA256.digest(params['key'] + bin2hex(salt))
                aes.iv = iv

                bin2hex(aes.update(content) + aes.final).strip
            end
        end
    end
end

Liquid::Template.register_tag('encrypted', Jekyll::Tags::EncryptionTag)