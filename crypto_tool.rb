=begin
    TwitterShoes
    crypto_tool.rb
    ruby script created to be a Twitter (http://www.twitter.com) client,
    that uses Shoes.rb to be run on various platforms (Linux, MacOSX, Windows).
    Copyright (C) 2008 Terence Lee <hone02@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end
require 'openssl'
require 'openssl/cipher' # evidently if I don't require this, shoes can't find the random_key/random_iv methods for the Cipher

# holds all the encrypted data as 3-way tuple
class EncryptedData < Struct.new( :data, :key, :iv )
end

# tool for encrypting/decrypting data based off of this blog post: http://stuff-things.net/2008/02/05/encrypting-lots-of-sensitive-data-with-ruby-on-rails/
class CryptoTool
  CIPHER = 'aes-256-cbc'

  # decrypt data
  def self.decrypt( password, private_key_file, encrypted_data )
    private_key = OpenSSL::PKey::RSA.new( File.read( private_key_file ), password )
    cipher = OpenSSL::Cipher::Cipher.new( CIPHER )
    cipher.decrypt
    cipher.key = private_key.private_decrypt( encrypted_data.key )
    cipher.iv = private_key.private_decrypt( encrypted_data.iv )

    decrypted_data = cipher.update( encrypted_data.data )
    decrypted_data << cipher.final

    decrypted_data
  end

  # encrypt data
  def self.encrypt( plaintext, public_key_file )
    public_key = OpenSSL::PKey::RSA.new( File.read( public_key_file ) )
    cipher = OpenSSL::Cipher::Cipher.new( CIPHER )
    cipher.encrypt # set into encrypt mode

    # generate random keys and IVs
    cipher.key = random_key = cipher.random_key
    cipher.iv = random_iv = cipher.random_iv

    encrypted_data = EncryptedData.new
    encrypted_data.data = cipher.update( plaintext )
    encrypted_data.data << cipher.final

    encrypted_data.key = public_key.public_encrypt( random_key )
    encrypted_data.iv = public_key.public_encrypt( random_iv )

    encrypted_data
  end
end
