# encoding: utf-8
require 'rspec'
require './lib/pronunciation_guidance'

describe 'pronunciation guidance' do
    it 'it should each character without expansion if no expansion exists' do
     	PronunciationGuidance.chinese("1234").should == "1, 2, 3, 4"
    end

    it 'should match the longest matchers first' do
		PronunciationGuidance.chinese("b").should == "<em>b</em>oy"
		PronunciationGuidance.chinese("ng").should == "so<em>ng</em>"
		PronunciationGuidance.chinese("ngb").should == "so<em>ng</em>, <em>b</em>oy"
		PronunciationGuidance.chinese("nngb").should == "<em>n</em>imble, so<em>ng</em>, <em>b</em>oy"
    end

    it 'should handle the a character with accents' do
		PronunciationGuidance.chinese("ā").should == "m<em>a</em>"
		PronunciationGuidance.chinese("é").should == "<em>e</em>arn"
		PronunciationGuidance.chinese("í").should == "s<em>i</em>t"
		PronunciationGuidance.chinese("ò").should == "dr<em>o</em>p"
		PronunciationGuidance.chinese("ū").should == "l<em>oo</em>k"
    end

    it 'should handle combined vowels with accents' do
		PronunciationGuidance.chinese("ai").should == "<em>eye</em>"
		PronunciationGuidance.chinese("āi").should == "<em>eye</em>"
		PronunciationGuidance.chinese("aí").should == "<em>eye</em>"
		PronunciationGuidance.chinese("āí").should == "<em>eye</em>"
		PronunciationGuidance.chinese("üe").should == "<em>we</em>t"
		PronunciationGuidance.chinese("íao").should == "m<em>eow</em>"
		PronunciationGuidance.chinese("iāo").should == "m<em>eow</em>"
		PronunciationGuidance.chinese("iaò").should == "m<em>eow</em>"
		PronunciationGuidance.chinese("íāò").should == "m<em>eow</em>"
    end

    it 'should handle a forward and back checks' do
		PronunciationGuidance.chinese("iā").should == "<em>ea</em>r"
		PronunciationGuidance.chinese("iās").should == "<em>ea</em>r, <em>s</em>on"
		PronunciationGuidance.chinese("ān").should == "m<em>a</em>, <em>n</em>imble"
		PronunciationGuidance.chinese("jān").should == "<em>j</em>eep, m<em>a</em>, <em>n</em>imble"
		PronunciationGuidance.chinese("iān").should == "<em>ea</em>r, <em>n</em>imble"


		PronunciationGuidance.chinese("én").should == "<em>e</em>arn, <em>n</em>imble"
		PronunciationGuidance.chinese("né").should == "<em>n</em>imble, <em>e</em>arn"
		PronunciationGuidance.chinese("ié").should == "<em>air</em>"
		PronunciationGuidance.chinese("ué").should == "l<em>oo</em>k, g<em>e</em>t"

		PronunciationGuidance.chinese("zhi").should == "slu<em>dg</em>e, vocalised <em>r</em>"
		PronunciationGuidance.chinese("zwi").should == "wor<em>ds</em>, <em>w</em>e, s<em>i</em>t"
		PronunciationGuidance.chinese("chi").should == "<em>ch</em>ildren, vocalised <em>r</em>"
		PronunciationGuidance.chinese("cwi").should == "ea<em>ts</em>, <em>w</em>e, s<em>i</em>t"
		PronunciationGuidance.chinese("shi").should == "<em>sh</em>ake, vocalised <em>r</em>"
		PronunciationGuidance.chinese("swi").should == "<em>s</em>on, <em>w</em>e, s<em>i</em>t"
		PronunciationGuidance.chinese("ri").should == "<em>r</em>aw, vocalised <em>r</em>"
		PronunciationGuidance.chinese("di").should == "<em>d</em>ig, s<em>i</em>t"
		PronunciationGuidance.chinese("hi").should == "<em>h</em>ot, s<em>i</em>t"

		PronunciationGuidance.chinese("zi").should == "wor<em>ds</em>, <em>i</em> like a buzzing bee"
		PronunciationGuidance.chinese("ci").should == "ea<em>ts</em>, <em>i</em> like a buzzing bee"
		PronunciationGuidance.chinese("si").should == "<em>s</em>on, <em>i</em> like a buzzing bee"

		PronunciationGuidance.chinese("on").should == "dr<em>o</em>p, <em>n</em>imble"
		PronunciationGuidance.chinese("ohg").should == "dr<em>o</em>p, <em>h</em>ot, <em>g</em>ood"
		PronunciationGuidance.chinese("ong").should == "s<em>o</em>w, so<em>ng</em>"
    end
end