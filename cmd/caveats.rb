# typed: strict
# frozen_string_literal: true

# `brew caveats` — print the caveats of formulae and casks without installing.
#
# Vendored from https://github.com/rafaelgarrido/homebrew-caveats at
# commit a495abced8373e1051e037d726359c2c1518b2e6. Changed from upstream:
# formatting, to satisfy `brew style` in this tap; and output gating, so that
# a name with nothing to say prints nothing at all. Upstream emits a blank
# line per named argument rather than per printed block, and prints a bare
# `==> name: Caveats` header for a formula whose only caveats are shell
# completions, because `Caveats#empty?` counts those but `#to_s` omits them.
# Gating on the rendered string is what `brew info` itself does. Upstream also
# requires at least one named argument; this copy defaults to everything
# installed, minus dependency-only formulae unless `--all` is passed.
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
require "cask/caskroom"
require "caveats"
require "formula"
require "missing_formula"

module Homebrew
  module Cmd
    # Print the caveats of the named formulae and casks without installing them.
    class CaveatsCmd < AbstractCommand
      cmd_args do
        usage_banner "`caveats` [<options>] [<formula>|<cask> ...]"
        description <<~EOS
          Provides installation caveat descriptions from formulae and casks.

          With no named argument, describes everything installed: every cask,
          and every formula you asked for by name. Formulae pulled in only as
          another formula's dependency are skipped unless `--all` is passed.
          A named argument is always described, whatever it was installed as.
        EOS

        switch "--formula", "--formulae",
               description: "Treat all named arguments as formulae."
        switch "--cask", "--casks",
               description: "Treat all named arguments as casks."
        switch "--all",
               description: "Also describe formulae installed only as a dependency of another " \
                            "formula. Has no effect when a formula or cask is named."

        conflicts "--formula", "--cask"

        named_args [:formula, :cask]
      end

      sig { override.void }
      def run
        printed = false

        formulae_and_casks.each do |obj|
          case obj
          when Formula
            caveats = Caveats.new(obj).to_s.presence
            next if caveats.nil?

            puts_caveats(obj.full_name, caveats, separate: printed)
            printed = true
          when Cask::Cask
            caveats = obj.caveats.to_s.presence
            next if caveats.nil?

            puts_caveats(obj.to_s, caveats, separate: printed)
            printed = true
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

      # The formulae and casks to describe: the named ones, or everything
      # installed when nothing was named.
      def formulae_and_casks
        return args.named.to_formulae_and_casks_and_unavailable if args.named.any?

        formulae = args.cask? ? [] : installed_formulae
        casks = args.formula? ? [] : Cask::Caskroom.casks.sort_by(&:token)

        formulae + casks
      end

      # Installed formulae, minus the ones that arrived only as another
      # formula's dependency, which are libraries far more often than not.
      def installed_formulae
        formulae = Formula.installed
        formulae = formulae.select { |formula| Tab.for_formula(formula).installed_on_request } unless args.all?
        formulae.sort_by(&:full_name)
      end

      # Print one caveats block, preceded by a blank line only when an earlier
      # block was printed.
      def puts_caveats(name, caveats, separate:)
        puts if separate
        ohai "#{name}: Caveats", caveats
      end
    end
  end
end
