# coding: utf-8
# vim: set ft=ruby sts=2 ts=2 sw=2 expandtab fo-=t:
require 'spec_helper'

describe 'Conversion' do

=begin
=end

  it 'should create a document header with title, author and attributes' do
    input = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<book xmlns="http://docbook.org/ns/docbook">
<info>
<title>Document Title</title>
<author>
<firstname>Doc</firstname>
<surname>Writer</surname>
<email>doc@example.com</email>
</author>
</info>
<section>
<title>First Section</title>
<para>content</para>
</section>
</book>
    EOS

    expected = <<-EOS.rstrip
= Document Title
Doc Writer <doc@example.com>
:doctype: book
:sectnums:
:toc: left
:icons: font
:experimental:

== First Section


content
EOS

    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should convert guimenu element to menu macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook">File operations are found in the <guimenu>File</guimenu> menu.</para>
    EOS

    expected = 'menu:File[]'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert menuchoice element to menu macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook">Select <menuchoice><guimenu>File</guimenu><guisubmenu>Open Terminal</guisubmenu><guimenuitem>Default</guimenuitem></menuchoice>.</para>
    EOS

    expected = 'menu:File[Open Terminal > Default]'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert link element to uri macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <link xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</link> on Wikipedia.</para>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert uri element to uri macro' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <uri xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</uri> on Wikipedia.</para>
<para>All DocBook V5.0 elements are in the namespace <uri>http://docbook.org/ns/docbook</uri>.</para>
</article>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.

All DocBook V5.0 elements are in the namespace http://docbook.org/ns/docbook.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert ulink element to uri macro' do
    input = <<-EOS
<!DOCTYPE para PUBLIC "-//OASIS//DTD DocBook XML V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd">
<para xmlns="http://docbook.org/ns/docbook">Read about <ulink url="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</ulink> on Wikipedia.</para>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should use attribute refence for uri if matching uri attribute is present' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <uri xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</uri> on Wikipedia.</para>
    EOS

    expected = 'Read about {uri-orm}[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input, attributes: {
      'uri-orm' => 'http://en.wikipedia.org/wiki/Object-relational_mapping'
    }

    expect(output).to include(expected)
  end

  it 'should convert xref element to xref' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">See <xref linkend="usage"/> for more information.</para>
    EOS

    expected = '<<usage>>'

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to include(expected)
  end

  it 'should use explicit label on xref if provided' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">See <xref linkend="usage">Usage</xref> for more information.</para>
    EOS

    expected = '<<usage,Usage>>'

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to include(expected)
  end

  it 'should convert itemized list to unordered list' do
    input = <<-EOS
<itemizedlist xmlns="http://docbook.org/ns/docbook">
<listitem>
<para>Apples</para>
</listitem>
<listitem>
<para>Oranges</para>
</listitem>
<listitem>
<para>Bananas</para>
</listitem>
</itemizedlist>
    EOS

    expected = <<-EOS.rstrip
* Apples
* Oranges
* Bananas
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert orderedlist to unordered list' do
    input = <<-EOS
<orderedlist xmlns="http://docbook.org/ns/docbook">
<listitem>
<para>Apples</para>
</listitem>
<listitem>
<para>Oranges</para>
</listitem>
<listitem>
<para>Bananas</para>
</listitem>
</orderedlist>
    EOS

    expected = <<-EOS.rstrip
. Apples
. Oranges
. Bananas
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert various types to anonymous literal' do
    input = <<-EOS
<para>
<code>Apples</code>, <command>oranges</command>, <computeroutput>bananas</computeroutput>, <database>pears</database>, <function>grapes</function>, <literal>mangos</literal>, <tag>kiwis</tag>, and <userinput>persimmons</userinput>.
</para>
    EOS

    expected = <<-EOS.rstrip
``Apples``, ``oranges``, ``bananas``, ``pears``, ``grapes``, ``mangos``, ``kiwis``, and ``persimmons``.
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert quote to double quoted text' do
    input = '<para><quote>Apples</quote></para>'

    expected = '"`Apples`"'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert funcsynopsis to C source' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>

<funcsynopsis>
  <funcprototype>
    <?dbhtml funcsynopsis-style='ansi'?>
    <funcdef>int <function>rand</function></funcdef>
    <void/>
 </funcprototype>
</funcsynopsis>

<funcsynopsis>
  <funcsynopsisinfo>
#include &lt;varargs.h&gt;
  </funcsynopsisinfo>
  <funcprototype>
    <?dbhtml funcsynopsis-style='kr'?>
    <funcdef>int <function>max</function></funcdef>
    <varargs/>
  </funcprototype>
</funcsynopsis>

<funcsynopsis>
  <funcprototype>
  <?dbhtml funcsynopsis-style='ansi'?>
    <funcdef>void <function>qsort</function></funcdef>
    <paramdef>void *<parameter>dataptr</parameter>[]</paramdef>
      <paramdef>int <parameter>left</parameter></paramdef>
    <paramdef>int <parameter>right</parameter></paramdef>
      <paramdef>int <parameter>(*comp)</parameter>
      <funcparams>void *, void *</funcparams></paramdef>
  </funcprototype>
</funcsynopsis>

</article>
    EOS

    expected = <<-EOS.rstrip
[source,c]
----
int rand (void);
----

[source,c]
----
#include <varargs.h>

int max (...);
----

[source,c]
----
void qsort (void *dataptr[],
            int left,
            int right,
            int (*comp) (void *, void *));
----
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert note element to NOTE' do
    input = <<-EOS
<note>
  <para>
    Please note the fruit:
    <screen>Apple, oranges and bananas</screen>
  </para>
</note>
    EOS

    expected = <<-EOS.rstrip

[NOTE]
====
Please note the fruit: 
----
Apple, oranges and bananas
----
====
    EOS

    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should accept special section names without title' do
    input = '<bibliography></bibliography>'

    expected = '= Bibliography'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert quandaset elements to Q and A list' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>
  <qandaset>
    <qandadiv>
      <title>Various Questions</title>
      <qandaentry xml:id="some-question">
        <question>
          <para>My question?</para>
        </question>
        <answer>
          <para>My answer!</para>
        </answer>
      </qandaentry>
      <qandaentry>
        <question>
          <para>Another question?</para>
        </question>
        <answer>
          <para>Another answer!</para>
        </answer>
      </qandaentry>
    </qandadiv>
  </qandaset>
  <para>A paragraph</para>
</article>
    EOS

    expected = <<-EOS.rstrip
.Various Questions

[qanda]
[[_some_question]]
My question?::

My answer!

Another question?::

Another answer!


A paragraph
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert emphasis elements to emphasized text' do
    input = "<para><emphasis>Apple</emphasis> or <emphasis>pine</emphasis>apple.</para>"

    expected = "_Apple_ or __pine__apple"

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert bibliography section to bibliography section' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

<bibliography xml:id="references">
<bibliomixed>
<abbrev>RNCTUT</abbrev>
Clark, James – Cowan, John – MURATA, Makoto: <title>RELAX NG Compact Syntax Tutorial</title>.
Working Draft, 26 March 2003. OASIS. <bibliomisc><link xl:href="http://relaxng.org/compact-tutorial-20030326.html"/></bibliomisc>
</bibliomixed>
</bibliography>

</article>
    EOS

    expected = <<-EOS.rstrip
[bibliography]
[[_references]]
== Bibliography
- [[[RNCTUT]]] 
Clark, James – Cowan, John – MURATA, Makoto: RELAX NG Compact Syntax Tutorial.
Working Draft, 26 March 2003. OASIS. http://relaxng.org/compact-tutorial-20030326.html
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert abbrev and acronym to monospaced' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

<para><acronym>Scuba</acronym> is an acronym while <abbrev>NSA</abbrev> is an abbreviation</para>

</article>
    EOS

    expected = <<-EOS.rstrip
`Scuba` is an acronym while `NSA` is an abbreviation
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should deal with incorrect numcols values' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <table>
    <title>Control parameters</title>
    <tgroup cols="5">
      <thead>
        <row>
          <entry>Apple</entry>
          <entry>Bear</entry>
          <entry>Carrot</entry>
          <entry>Dam</entry>
        </row>
      </thead>
    </tgroup>
  </table>
</article>
    EOS
   expected = <<-EOS.rstrip
.Control parameters
[cols="1,1,1,1,1", options="header"]
|===
| Apple
| Bear
| Carrot
| Dam
|===
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert nested program listings in listitems correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <para>Some examples:
    <itemizedlist>
      <listitem>
        <para>get all process definitions</para>
        <para>
          <programlisting>Collection mousse = service.getChocolate();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>get active process instances
          <programlisting>Collection rum = service.getRaisin();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>get tasks assigned to john
          <programlisting>List moonshine = service.getCinnamon();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>this listitem has....</para>
        <para>...multiple elements!</para>
        <para>So there should be continuations!</para>
      </listitem>
    </itemizedlist>

    But a newline at the end</para>
</article>
    EOS

    expected = <<-EOS.rstrip

Some examples: 

* get all process definitions
+
[source]
----
Collection mousse = service.getChocolate();
----
* get active process instances 
+
[source]
----
Collection rum = service.getRaisin();
----
* get tasks assigned to john 
+
[source]
----
List moonshine = service.getCinnamon();
----
* this listitem has....
+ 
...multiple elements!
+ 
So there should be continuations!

But a newline at the end
   EOS
    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should convert emphasis bold elements correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <para><emphasis role="bold">Singleton strategy</emphasis>- instructs RuntimeManager to do stuff</para>
</article>
    EOS

    expected = <<-EOS.rstrip
**Singleton strategy**- instructs RuntimeManager to do stuff
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert nested listitems correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <itemizedlist>
    <listitem>
      <para>simple</para>
    </listitem>
    <listitem>
      <para>compact</para>
      <itemizedlist>
        <listitem>
          <para>design</para>
        </listitem>
        <listitem>
          <para>value</para>
        </listitem>
      </itemizedlist>
    </listitem>
    <listitem>
      <para>orcas</para>

      <orderedlist>
        <listitem>
          <para>tuna</para>

          <itemizedlist>
            <listitem>
              <para>squid</para>

              <orderedlist>
                <listitem>
                  <para>shrimp</para>
                </listitem>
              </orderedlist>

            </listitem>
          </itemizedlist>

        </listitem>
        <listitem>
          <para>manta rays</para>
        </listitem>
      </orderedlist>

    </listitem>
  </itemizedlist>
  <para>break!</para>
  <itemizedlist>
    <listitem>
      <para>layer</para>
    </listitem>
    <listitem>
      <para>cake</para>
      <itemizedlist>
        <listitem>
          <para>is a</para>
          <itemizedlist>
            <listitem>
              <para>great film!</para>
            </listitem>
          </itemizedlist>
        </listitem>
      </itemizedlist>
    </listitem>
  <itemizedlist>
</article>
    EOS

    expected = <<-EOS

* simple
* compact
** design
** value
* orcas
.. tuna
*** squid
.... shrimp
.. manta rays


break!

* layer
* cake
** is a
*** great film!
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should add all table lines and escape | characters in table text' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <table>
    <tgroup cols="4"> 
      <thead>
        <row>
          <entry>Name</entry>
          <entry>Possible values</entry>
          <entry>Default value</entry>
          <entry>Description|Identity</entry>
        </row>
      </thead>
      <tbody>
        <row>
          <entry>Tom</entry>
          <entry>true|false|unknown</entry>
          <entry>unknown</entry>
          <entry>The quantum postman</entry>
        </row>
      </tbody>
     </tgroup>
  </table>    
</article>
    EOS

    expected = <<-EOS.rstrip

[cols="1,1,1,1", options="header"]
|===
| Name
| Possible values
| Default value
| Description\\|Identity


|Tom
|true\\|false\\|unknown
|unknown
|The quantum postman
|===
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should correctly nest formatting (bold, emphasized, literal) in text' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
   <itemizedlist>
      <listitem>
        <para><emphasis role="bold">bold</emphasis></para>
      </listitem>
      <listitem>
        <para><code>code</code></para>
      </listitem>
      <listitem>
        <para><emphasis>italics</emphasis></para>
      </listitem>
      <listitem>
        <para>
          <emphasis role="bold">bold, <emphasis>bold italics</emphasis></emphasis><emphasis>, and italics</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis>italics, <emphasis role="bold">italicized bold</emphasis></emphasis><emphasis role="bold">, and bold</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis>empha-<code>\#{code}</code>-sized</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis role="bold">bold-<code>code</code></emphasis></para>
      </listitem>
      <listitem>
        <para>Really hard to fix elegantly.. and an outer edge case.<!-- <emphasis>Not</emphasis><emphasis role="bold">Bold<emphasis>But<code>Ridiculous</code></emphasis></emphasis> --></para>
      </listitem>
      <listitem>
        <para><code>CodeNormal<emphasis>Italics</emphasis><emphasis role="bold">Bold</emphasis><emphasis><emphasis role="bold">Ridiculous</emphasis></emphasis></code></para>
      </listitem>
      <listitem>
        <para><code>_underscores_in_code_</code></para>
      </listitem>
      <listitem>
        <para><code>*starry*code**</code></para>
      </listitem>
    </itemizedlist>
</article>
    EOS

    expected = <<-EOS.rstrip

* *bold*
* `code`
* _italics_
* **bold, __bold italics__**__, and italics__
* __italics, **italicized bold**__**, and bold**
* _empha-``__\\\#{code}__``-sized_
* *bold-``**code**``*
* Really hard to fix elegantly.. and an outer edge case.
* `CodeNormal__Italics__**Bold**__**Ridiculous**__`
* `\\_underscores_in_code_`
* `\\*starry*code**`
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert escape hashes in literal or formatted text' do
    input = '<para><code><emphasis>#{expression}</emphasis></code></para>'

    expected = '`__\#{expression}__`'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert bridgeheads without renderas attributes' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <section>
    <title>Section title</title>
    <bridgehead>Section bridgehead</bridgehead>
    <bridgehead renderas="sect3">level-three</bridgehead>

    <section>
      <title>subsub</title>
      <bridgehead>bridgebridge</bridgehead>
      <bridgehead renderas="sect1">level-one</bridgehead>
    </section>

  </section>
</article>
    EOS

    expected = <<-EOS.rstrip

== Section title

[float]
=== Section bridgehead

[float]
==== level-three

=== subsub

[float]
==== bridgebridge

[float]
== level-one
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should process nested admonitions and other things in lists correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

  <itemizedlist>
    <listitem>Simple text</listitem>
    <listitem><emphasis>Not</emphasis> all of the text!</listitem>
    <listitem><para>Simple para</para></listitem>
    <listitem>
        <para>Para between text</para>
    </listitem>
    <listitem>
      <note>
        <para>Note text</para>
      </note>
      <para>List text</para>
    </listitem>
    <listitem>
      <note>
        <para>Two</para>
      </note>
      <note>
        <para>Notes</para>
      </note>
    </listitem>
    <listitem>
      <note>
        <para>One note</para>
      </note>
    </listitem>
    <listitem>
      <para>Craziness: text and then.. </para>
      <note>
        <para>.. a note...</para>
      </note>
      <para>...and then more text?!?</para>
    </listitem>
    <listitem>
      <note>
        <para>.. a note...</para>
      </note>
      <itemizedlist>
        <listitem>
          <para>Crazier</para>
          <itemizedlist>
            <listitem><para>Craziest</para></listitem>
          </itemizedlist>
        </listitem>
      </itemizedlist>
      <para>Crazy</para>
    </listitem>  
  </itemizedlist>

</article>
    EOS

    expected = <<-EOS.rstrip

* Simple text
* _Not_ all of the text!
* Simple para
* Para between text
* {empty}
+

[NOTE]
====
Note text
====
+
List text
* {empty}
+

[NOTE]
====
Two
====
+

[NOTE]
====
Notes
====
* {empty}
+

[NOTE]
====
One note
====
* Craziness: text and then.. 
+

[NOTE]
====
$$..$$ a note...
====
+
...and then more text?!?
* {empty}
+

[NOTE]
====
$$..$$ a note...
====
** Crazier
*** Craziest

+
Crazy
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'adds a new line after figures' do

    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <para>Non-global stories:
  <figure>
      <title>Local History</title>
      <screenshot>
        <mediaobject>
          <imageobject>
            <imagedata fileref="Designer/localhistory1.png"/>
          </imageobject>
        </mediaobject>
      </screenshot>
    </figure>

    The Local History results screen allows stuff.

    <figure>
      <title>Local History Sample Results</title>
      <screenshot>
        <mediaobject>
          <imageobject>
            <imagedata fileref="Designer/localhistory-results.png"/>
          </imageobject>
        </mediaobject>
      </screenshot>
    </figure>
    And sometimes it does not.</para>

</article>
    EOS

    expected = <<-EOS.rstrip
Non-global stories: 

.Local History
image::Designer/localhistory1.png[]

The Local History results screen allows stuff. 

.Local History Sample Results
image::Designer/localhistory-results.png[]

And sometimes it does not.
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should correctly convert varlistentry elements with nested lists' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

  <variablelist>
    <varlistentry>
      <term><command>showStartProcessForm(hostUrl)</command>:
            Makes a call to the REST endpoint.</term>
      <listitem>
        <itemizedlist>
          <listitem>
            <para><emphasis>hostURL</emphasis>: the URL</para>
          </listitem>
          <listitem>
            <para><emphasis>deploymentId</emphasis>: the deployment identifier</para>
          </listitem>
          <listitem>
            <para><emphasis>processId</emphasis>: the identifier of the process</para>
          </listitem>
        </itemizedlist>
      </listitem>
    </varlistentry>
    <varlistentry>
      <term><command>startProcess(divId)</command>:
        Submits the form loaded.</term>
      <listitem>
        <itemizedlist>
          <listitem>
            <para><emphasis>divId</emphasis>: the identifier</para>
          </listitem>
          <listitem>
            <para><emphasis>onsuccessCallback</emphasis> (optional): a javascript function</para>
          </listitem>
          <listitem>
            <para><emphasis>onerrorCallback</emphasis> (optional): a javascript function</para>
          </listitem>
        </itemizedlist>
      </listitem>
    </varlistentry>
  </variablelist>
</article>
    EOS

    expected = <<-EOS.rstrip

``showStartProcessForm(hostUrl)``: Makes a call to the REST endpoint.::

* __hostURL__: the URL
* __deploymentId__: the deployment identifier
* __processId__: the identifier of the process

``startProcess(divId)``: Submits the form loaded.::

* __divId__: the identifier
* _onsuccessCallback_ (optional): a javascript function
* _onerrorCallback_ (optional): a javascript function
EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'convert variable lists with multiple para elements per entry' do
    input = <<-EOS
 <variablelist>
      <varlistentry>
        <term><literal>no-loop</literal></term>

        <listitem>
          <para>default value: <literal>false</literal></para>

          <para>type: Boolean</para>

          <para>When a rule's consequence modifies a fact it may cause the
          rule to activate again, causing an infinite loop. Setting no-loop to
          true will skip the creation of another Activation for the rule with
          the current set of facts.</para>
        </listitem>
      </varlistentry>

      <varlistentry>
        <term><literal>ruleflow-group</literal></term>

        <listitem>
          <para>default value: N/A</para>

          <para>type: String</para>

          <para>Ruleflow is a Drools feature that lets you exercise control
          over the firing of rules. Rules that are assembled by the same
          ruleflow-group identifier fire only when their group is
          active.</para>
        </listitem>
      </varlistentry>
    EOS

    expected = <<-EOS.rstrip

`no-loop`::
default value: `false`
+
type: Boolean
+
When a rule's consequence modifies a fact it may cause the rule to activate again, causing an infinite loop.
Setting no-loop to true will skip the creation of another Activation for the rule with the current set of facts.

`ruleflow-group`::
default value: N/A
+
type: String
+
Ruleflow is a Drools feature that lets you exercise control over the firing of rules.
Rules that are assembled by the same ruleflow-group identifier fire only when their group is active.
EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should handle direct title and subtitle' do
    input = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<book xmlns="http://docbook.org/ns/docbook">
<title>book title</title>
<subtitle>book subtitle</subtitle>
<info>
<author>
<firstname>Doc</firstname>
<surname>Writer</surname>
<email>doc@example.com</email>
</author>
</info>
<section>
<title>First Section</title>
<para>content</para>
</section>
</book>
    EOS

    expected = <<-EOS.rstrip
= book title: book subtitle
Doc Writer <doc@example.com>
:doctype: book
:sectnums:
:toc: left
:icons: font
:experimental:

== First Section


content
EOS

    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should convert procedure corectly' do
    input = <<-EOS
<procedure>
  <title>How</title>
  <step>
    <para>step 1</para>
  </step>
  <step>
    <para>step 2</para>
  </step>
  <step>
    <para>step 3</para>
  </step>
  <step>
    <para>step 4</para>
    <substeps>
      <step>
        <para>step 4.1</para>
      </step>
      <step>
        <para>step 4.2</para>
      </step>
      <step>
        <para>step 4.3</para>
      </step>
    </substeps>
  </step>
  <step>
    <para>step 5</para>
  </step>
  <step>
    <para>step 6</para>
    <substeps>
      <step>
        <para>step 6.1</para>
      </step>
      <step>
        <para>step 6.2</para>
      </step>
    </substeps>
  </step>
  <step>
    <para>step 7</para>
  </step>
  <step>
    <para>step 8</para>
  </step>
  <step>
    <para>step 9</para>
  </step>
</procedure>
    EOS

    expected = <<-EOS

.Procedure: How
. step 1
. step 2
. step 3
. step 4
+
.. step 4.1
.. step 4.2
.. step 4.3
. step 5
. step 6
+
.. step 6.1
.. step 6.2
. step 7
. step 8
. step 9
    EOS
    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'it should ' do
    input = <<-EOS
<procedure>
  <title>How</title>
  <step>
    <para>step 1</para>
  </step>
  <step>
    <para>step 2</para>
  </step>
  <step>
    <para>step 3</para>
  </step>
  <step>
    <para>step 4</para>
    <substeps>
      <step>
        <para>step 4.1</para>
      </step>
      <step>
        <para>step 4.2</para>
      </step>
      <step>
        <para>step 4.3</para>
      </step>
    </substeps>
  </step>
  <step>
    <para>step 5</para>
  </step>
  <step>
    <para>step 6</para>
    <substeps>
      <step>
        <para>step 6.1</para>
      </step>
      <step>
        <para>step 6.2</para>
      </step>
    </substeps>
  </step>
  <step>
    <para>step 7</para>
  </step>
  <step>
    <para>step 8</para>
  </step>
  <step>
    <para>step 9</para>
  </step>
</procedure>
    EOS

    expected = <<-EOS

.Procedure: How
. step 1
. step 2
. step 3
. step 4
+
.. step 4.1
.. step 4.2
.. step 4.3
. step 5
. step 6
+
.. step 6.1
.. step 6.2
. step 7
. step 8
. step 9
    EOS
    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should not add blank/space/newline after xref in middle of para' do
    input = <<-EOS
<para>BEGIN <emphasis role="bold">Chapter 4: Contact Details</emphasis> (<xref linkend="C-Contact-Details"/>) END</para>
    EOS

    expected = <<-EOS.chomp

BEGIN *Chapter 4: Contact Details* (<<C-Contact-Details>>) END
    EOS

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to eq(expected)
  end

  it 'should handle spaces inside emphasis correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>

<section>
<title>test cases with role=bold</title>
<para>BEGIN <emphasis role="bold">wemphasis wbold nospace</emphasis> END</para>
<para>BEGIN <emphasis role="bold">wemphasis wbold espace </emphasis> END</para>
<para>BEGIN <emphasis role="bold"> wemphasis wbold sspace</emphasis> END</para>
<para>BEGIN <emphasis role="bold"> wemphasis wbold bspace </emphasis> END</para>
</section>

<section>
<title>test cases with role=strong</title>
<para>BEGIN <emphasis role="strong">wemphasis wstrong nospace</emphasis> END</para>
<para>BEGIN <emphasis role="strong">wemphasis wstrong espace </emphasis> END</para>
<para>BEGIN <emphasis role="strong"> wemphasis wstrong sspace</emphasis> END</para>
<para>BEGIN <emphasis role="strong"> wemphasis wstrong bspace </emphasis> END</para>
</section>

<section>
<title>test cases with role=marked</title>
<para>BEGIN <emphasis role="marked">wemphasis wmarked nospace</emphasis> END</para>
<para>BEGIN <emphasis role="marked">wemphasis wmarked espace </emphasis> END</para>
<para>BEGIN <emphasis role="marked"> wemphasis wmarked sspace</emphasis> END</para>
<para>BEGIN <emphasis role="marked"> wemphasis wmarked bspace </emphasis> END</para>
</section>

<section>
<title>test cases with norole</title>
<para>BEGIN <emphasis>wemphasis wnorole nospace</emphasis> END</para>
<para>BEGIN <emphasis>wemphasis wnorole espace </emphasis> END</para>
<para>BEGIN <emphasis> wemphasis wnorole sspace</emphasis> END</para>
<para>BEGIN <emphasis> wemphasis wnorole bspace </emphasis> END</para>
</section>

</article>
    EOS

    expected = <<-EOS.chomp

== test cases with role=bold


BEGIN *wemphasis wbold nospace* END

BEGIN **wemphasis wbold espace ** END

BEGIN ** wemphasis wbold sspace** END

BEGIN ** wemphasis wbold bspace ** END

== test cases with role=strong


BEGIN *wemphasis wstrong nospace* END

BEGIN **wemphasis wstrong espace ** END

BEGIN ** wemphasis wstrong sspace** END

BEGIN ** wemphasis wstrong bspace ** END

== test cases with role=marked


BEGIN #wemphasis wmarked nospace# END

BEGIN ##wemphasis wmarked espace ## END

BEGIN ## wemphasis wmarked sspace## END

BEGIN ## wemphasis wmarked bspace ## END

== test cases with norole


BEGIN _wemphasis wnorole nospace_ END

BEGIN __wemphasis wnorole espace __ END

BEGIN __ wemphasis wnorole sspace__ END

BEGIN __ wemphasis wnorole bspace __ END
    EOS

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to eq(expected)
  end


  it 'should not not drop space/newline between adjacent elements' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>

<para> <emphasis role="bold">wemphasis</emphasis> drop leading space</para>

<para>drop trailing space <emphasis role="bold">wemphasis</emphasis> </para>

<para>keep space in in middle: first line
before-wlinkend <xref linkend="wlinkend"/> <emphasis role="bold">wemphasis</emphasis> after wemphasis
lastline</para>

<para>keep newline in the middle: first line
before-wlinkend <xref linkend="wlinkend"/>
<emphasis role="bold">wemphasis</emphasis> after wemphasis
lastline</para>

</article>
    EOS

    expected = <<-EOS.chomp

*wemphasis* drop leading space

drop trailing space *wemphasis*

keep space in in middle: first line before-wlinkend <<wlinkend>> *wemphasis* after wemphasis lastline

keep newline in the middle: first line before-wlinkend <<wlinkend>> *wemphasis* after wemphasis lastline
    EOS

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to eq(expected)
  end

end
