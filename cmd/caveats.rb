# typed: strict
# frozen_string_literal: true

# `brew caveats` — print the caveats of formulae and casks without installing.
#
# Vendored from https://github.com/rafaelgarrido/homebrew-caveats at
# commit a495abced8373e1051e037d726359c2c1518b2e6. Only formatting was
# changed, to satisfy `brew style` in this tap.
#
# SPDX-License-Identifier: MIT
#
# Copyright (c) 2021 Rafael Garrido
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "abstract_command"
require "caveats"
require "formula"
require "missing_formula"

module Homebrew
  module Cmd
    # Print the caveats of the named formulae and casks without installing them.
    class CaveatsCmd < AbstractCommand
      cmd_args do
        usage_banner "`caveats` <formulae1> <formulae2> ..."
        description <<~EOS
          Provides installation caveat descriptions from formulae and casks.
        EOS

        switch "--formula", "--formulae",
               description: "Treat all named arguments as formulae."
        switch "--cask", "--casks",
               description: "Treat all named arguments as casks."

        conflicts "--formula", "--cask"

        named_args [:formula, :cask], min: 1
      end

      sig { override.void }
      def run
        args.named.to_formulae_and_casks_and_unavailable.each_with_index do |obj, i|
          puts unless i.zero?

          case obj
          when Formula
            puts_formula_caveats(obj)
          when Cask::Cask
            puts_cask_caveats(obj)
          when FormulaOrCaskUnavailableError
            # The formula/cask could not be found
            ofail obj.message
            # No formula with this name, try a missing formula lookup
            if (reason = MissingFormula.reason(obj.name, show_info: true))
              $stderr.puts reason
            end
          else
            raise
          end
        end
      end

      def puts_formula_caveats(formula)
        caveats = Caveats.new(formula)
        return if caveats.empty?

        ohai "#{formula.full_name}: Caveats", caveats.to_s
        puts
      end

      def puts_cask_caveats(cask)
        return if cask.caveats.empty?

        ohai "#{cask}: Caveats", cask.caveats
        puts
      end
    end
  end
end
