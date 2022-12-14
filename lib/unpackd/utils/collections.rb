module Unpackd
  module Utils
    module Collections
      # Converts the given `array` into a `Hash`.
      #
      # @param array [Array] the array to convert into a hash
      # @return [Hash] the converted hash
      def array_to_hash(array)
        {}.tap do |hash|
          array.each_with_index do |value, index|
            next if (result = block_given? ? yield(value) : value).nil?
            hash[index] = result
          end
          hash[array.size - 1] ||= nil unless array.empty?
        end
      end

      # Converts the given `hash` into an `Array`.
      #
      # @param hash [Hash] the hash to convert into an array
      # @return [Array] the converted array
      def hash_to_array(hash)
        [].tap { |array| hash.each { |index, value| array[index] = value } }
      end
    end
  end
end
