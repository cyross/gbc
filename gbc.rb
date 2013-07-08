# -*- encoding: utf-8 -*-

class LabelError
  def self.cannot_find_label(vp)
    $stderr.puts("Cannot find label! : #{vp}")
    exit
  end

  def self.fix_only(label, labels)
    s = labels.join(" or ")
    $stderr.puts("#{s} labal can use only fixed paragraph!! : #{label}")
    exit
  end

  def self.duplicate(label)
    $stderr.puts("duplicate label! : #{label}")
    exit
  end

  def self.reserved_by_fixed_label(label, fixed)
    $stderr.puts("#{label} is used by fixed label #{fixed}!")
    exit
  end

  def self.under_first(label, first)
    $stderr.puts("fixed paragraph number #{label} is under first paragraph number(#{first})!")
    exit
  end

  def self.over_last(label, last)
    $stderr.puts("fixed paragraph number #{label} is over last paragraph number(#{last})!")
    exit
  end
end

class ParagraphError
  def self.empty(vp)
    $stderr.puts("Paragraph #{vp} is empty!")
    exit
  end

  def self.label_declare_first(line)
    $stderr.puts("you must declare label! : #{line}")
    exit
  end
end

class ScenarioError
  def self.empty
    $stderr.puts("Scenario is empty!")
    exit
  end
end

class Formatter
  def initialize
    @comment_regexp = %r|^[\s\t]*#|
    @label_regexp = %r|##([^#]+)##|
  end

  def pre_process(lines)
    lines.delete_if{|line|
      @comment_regexp.match(line)
    }
  end

  def convert(paragraphs, line)
    while @label_regexp.match(line) do
      vp = $1
      num = paragraphs.shuffled_paragraphs[vp]
      LabelError.cannot_find_label(vp) unless num
      line.sub!(@label_regexp, num)
    end
    line
  end

  def post_process(paragraphs, vnum, pnum, lines)
    lines
  end

  def output(paragraphs, num, lines)
    puts "*#{num}"
    lines.each{|line| puts line }
  end

  def shuffle?
    true
  end

  def out_type
    "gamebook"
  end
end

class FirstParagraphProcessor
  def regexp
    %r|^FIRST=(\d+)|
  end

  def process(paragraphs, line, match_data)
    paragraphs.first_paragraph = match_data[1].to_i
  end 
end

class ParagraphNumberProcessor
  def initialize(prefix="\\*")
    @prefix = prefix
  end

  def regexp
    %r|^#{@prefix}([^\r\n]+)|
  end

  def process(paragraphs, line, match_data)
    label = match_data[1]
    labels = paragraphs.reserved_labels
    LabelError.fix_only(label, labels) if labels.include?(label) 
    paragraphs.add(label)
  end
end

class FixedParagraphNumberProcessor
  def initialize(prefix="\\*")
    @prefix = prefix
  end

  def regexp
    %r|^#{@prefix}#{@prefix}([^\r\n]+)|
  end

  def process(paragraphs, line, match_data)
    paragraphs.add(match_data[1], true)
  end
end

class CommentProcessor
  def initialize(prefix="\\#")
    @prefix = prefix
  end

  def regexp
    %r|^[\s\t]*#{@prefix}|
  end

  def process(paragraphs, line, match_data)
    # nop
  end
end

class Paragraphs
  @@first_label = "FIRST"
  @@last_label = "LAST"

  def initialize(formatter, paragraph_prefix = "\\*", processors = [])
    @formatter = formatter
    @reserved_labels = [@@first_label, @@last_label]
    @processors = [
      FirstParagraphProcessor.new,
      FixedParagraphNumberProcessor.new(paragraph_prefix),
      ParagraphNumberProcessor.new(paragraph_prefix)
    ] + processors
    @first_paragraph = 1
    @last_paragraph = 1
    @fixed_paragraphs = []
    @has_last_label = false
    @paragraphs = {}
    @paragraph = nil
    @shuffled_paragraphs = {}
  end

  def pre_process(lines)
    @formatter.pre_process(lines)
  end

  def post_process
    @paragraphs.each_key{|key|
      @paragraphs[key] = @formatter.post_process(@paragraphs, key, @shuffled_paragraphs[key], @paragraphs[key])
    }
  end

  def analyze(lines)
    lines.each{|line|
      r = @processors.each{|processor|
        if match_data = processor.regexp.match(line)
          processor.process(self, line, match_data)
          break
        end
        true
      }
      if r
        ParagraphError.label_declare_first(line) unless @paragraph
        next if @paragraphs[@paragraph].length == 0 and line.sub(%r|^[\s\t]+|, "").empty?
        @paragraphs[@paragraph] << line
      end
    }
    @last_paragraph = @first_paragraph + @paragraphs.size - 1
    #puts "first paragraph : #{@first_paragraph}"
    #puts "lstt paragraph : #{@last_paragraph}"
    analyze_error_check
  end

  def analyze_error_check
    labels = @fixed_paragraphs
    first  = @first_paragraph.to_s
    last   = @last_paragraph.to_s
    LabelError.cannot_find_label(@@first_label) if (!labels.include?(@@first_label)) 
    LabelError.reserved_by_fixed_label(first, @@first_label) if (labels.include?(first.to_s)) 
    LabelError.reserved_by_fixed_label(last, @@last_label) if (labels.include?(@@last_label) and labels.include?(last)) 
    labels.each{|label|
      next if @reserved_labels.include?(label)
      label = label.to_i
      LabelError.under_first(label, first) if label < first
      LabelError.over_last(label, last) if label > last
    }
  end

  def add(vparagraph, fixed_paragraph = false)
    LabelError.duplicate(vparagraph) if @paragraphs.key?(vparagraph)
    ParagraphError.empty(@paragraph) if @paragraph and @paragraphs[@paragraph].size == 0
    @paragraph = vparagraph
    @fixed_paragraphs << @paragraph if fixed_paragraph
    @paragraphs[@paragraph] = []
  end

  def inner1(vps, label, n)
    vps.delete(label)
    @shuffled_paragraphs[label] = n
    vps
  end

  def process
    if @formatter.shuffle?
      shuffle
    else
      sequential
    end
    convert
  end

  def inner_preprocess(vps, from, to)
    @shuffled_paragraphs = {}
    if vps.include?(@@first_label)
      vps = inner1(vps, @@first_label, @first_paragraph.to_s)
      from = from + 1
    end
    if vps.include?(@@last_label)
      @has_last_label = true
      vps.delete(@@last_label)
      to = to - 1
    end
    [vps, from, to]
  end

  def inner_postprocess
    # if "LAST" in paragraph labals, insert last keys
    @shuffled_paragraphs[@@last_label] = @last_paragraph.to_s if @has_last_label
  end

  def shuffle
    vps, from, to = inner_preprocess(@paragraphs.keys, @first_paragraph, @last_paragraph)
    (from..to).each{|pnum|
      pnum = pnum.to_s
      vps = inner1(vps, @fixed_paragraphs.include?(pnum) ? pnum : vps.sample, pnum)
    }
    inner_postprocess
  end

  def sequential
    vps, from, to = inner_preprocess(@paragraphs.keys, @first_paragraph, @last_paragraph)
    (from..to).each{|pnum|
      vps = inner1(vps, vps[0], pnum.to_s)
    }
    inner_postprocess
  end

  def convert
    @paragraphs.each_key{|key|
      @paragraphs[key].map!{|line|
        @formatter.convert(self, line)
      }
    }
  end

  def output
    @shuffled_paragraphs.each_key{|key|
      @formatter.output(self, @shuffled_paragraphs[key], @paragraphs[key])
    }
  end

  attr_reader :shuffled_paragraphs, :reserved_labels
  attr_accessor :first_paragraph, :last_paragraph
end

class Converter
  def initialize(formatter, paragraph_prefix = "\\*", processors = [])
    @paragraphs = Paragraphs.new(formatter, paragraph_prefix, processors)
  end

  def analyze(lines)
    @paragraphs.analyze(@paragraphs.pre_process(lines))
  end

  def process
    @paragraphs.process
    @paragraphs.post_process
  end

  def output
    @paragraphs.output
  end
end

if __FILE__ == $0
  c = Converter.new(Formatter.new, "●")
  c.analyze($stdin.readlines)
  c.process
  c.output
end
