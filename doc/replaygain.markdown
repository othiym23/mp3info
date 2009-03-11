Calculation methods
===================

RVA / RVAD
----------

Calculation to produce dB gain adjustment:

![dB = 20 * log(1 +/- |x| / 2^bits)](rva-equation.png "RVA dB conversion equation")

Power curve:

![inverse L mapping -2^bits - 2^bits (scalar) to -90.1 - 6.1 dB](rva-scalar-to-dB.jpg "RVA power curve")

Of all the methods for calculating volume adjustment for MP3s, none are quirkier
than the frankly bizarre RVA[D] frame. The documentation for the frame
describes how the bytes are laid out within the frame without actually
describing how any of the values should be interpreted, and the adjustment
calculation implemented in the wild tries overly hard to create a linear mapping
of loudness to dB adjustment (hence the transposed logarithmic mapping).

Because the frame allows users to specify the precision of the adjustment (in
bits), it's theoretically possible to specify adjustments to an arbitrary
degree of accuracy. In practice, the precision almost always seems to be 16
bits.

iTunNORM
--------

Calculation to produce dB gain adjustment:

![dB = -10 log(x / scale)](iTunNORM-equation.png "iTunes dB conversion equation")

Power curve:

![inverse logarithmic curve mapping 0 - 65,534 to Infinity - -18.2](iTunNORM-scalar-to-dB.jpg "iTunes dB conversion equation")

As far as I know at the time of writing this, there is no confirmation from
anyone at Apple that this equation is actually how the gain adjustment is
calculated, but in practice it seems to work. Uniquely, Apple calculates (and
stores) normalization against both a 1 / 1000 dB-amp and a 1 / 2500 dB-amp
scale. It's not immediately clear to me why that would be useful, but given the
nonlinear nature of the equation used, perhaps it helps precisely triangulate
gain adjustments at extrema.

Then again, since the normalization iTunes uses is the Sirius Cybernetics
Nutrimatic Drinks Dispenser of replay volume adjustment methods, it was
probably just a bored engineer at Apple being excessively clever. The same
kind of thinking is evident in how iTunes calculates gain adjustments
independently for the left and right channels (a trait it shares with RVAD and
RVA2, but not mp3gain).

Unlike the RVAD calculation, which requires a separately-stored bitfield to
indicate whether a given gain adjustment is negative or positive, the
iTunNORM gain calculation requires only a positive domain to cover its entire
output range. Of course, this makes manually interpreting the stored scalar
values of the adjustment tricky, because with a scale of 1000 dB/milliamp, a
stored value of 1,000 is required to apply no adjustment to the gain.

XRV / XRVA / RVA2
-----------------

Calculation to produce dB gain adjustment:

![dB = x / 512](rva2-equation.png "RVA2 conversion equation")

Power curve:

![linear mapping of -2^bits - 2^bits to -2^(bits-1)/512 - 2^(bits-1)/512](rva2-scalar-to-dB.jpg "RVA power curve")

Set next to iTunes and the bizarre monstrosity of the RVAD frame, this frame
is both simple and sane, which is probably why it's been backported to previous
versions of ID3v2. It's a simple linear mapping that allows users to adjust gain to
1/512 dB.

Of course, it's still both more complicated and less precise than storing
actual fixed-point gain adjustments as text values in simple text frames, which
is why the APE tag / TXXX-frame method favored by mp3gain and foobar2k seems
to predominate now.

Links
=====

Overview
--------

* [Hydrogen Audio are the unofficial guardians of replay gain lore.](http://wiki.hydrogenaudio.org/index.php?title=Replaygain)
* [Songbird assembled a useful summary page while they were adding replay gain support to Songbird 1.1.](http://wiki.songbirdnest.com/QA/Releases/Hendrix_Test_Plan#Normalization_of_Playback_Volume)

LAME tag
--------

* [The canonical (and basically only) reference to the LAME tag, including its built-in support for replay gain.](http://gabriel.mp3-tech.org/mp3infotag.html#replaygain)
  
RVA
---

* [The ID3v2.2 de facto standard of RVA.](http://id3.org/id3v2-00#line-1001)
* [Replaygain reference from the Aqualung audio player's manual.](http://aqualung.factorial.hu/manual/aqualung-doc-part_6_3.html#id199755)

RVAD
----

* [The ID3v2.3 de facto standard description of RVAD.](http://www.id3.org/id3v2.3.0#sec4.12)
* [The only extant documentation of the bizarre RVAD / RVA scalar -> dB algorithm.](http://osdir.com/ml/multimedia.id3v2/2007-01/msg00062.html)
  
RVA2 / XRVA / XRV
-----------------

* [The ID3v2.4 de facto standard description of RVA2.](http://www.id3.org/id3v2.4.0-frames#line-971)
* [id3.org's description of backporting RVA2 support to ID3v2.3 and ID3v2.2.](http://www.id3.org/Experimental_RVA2)
* [The *normalize-audio* program uses XRVA frames.](http://normalize.nongnu.org/)
* [*normalize-audio* man page](http://olympus.het.brown.edu/cgi-bin/dwww?type=runman&location=normalize/1)
* [Details of how the Rockbox open firmware treats RVA2, XRVA and XRV frames as equivalent.](http://www.rockbox.org/tracker/task/1943)
* [Gentoo patch adding RVA2 support to XMMS.](http://bugs.gentoo.org/29477)

RGAD
----

* [Strawman proposal of the RGAD tag from Hydrogen Audio.](http://replaygain.hydrogenaudio.org/file_format_id3v2.html)
* [id3.org's codification of Hydrogen Audio's strawman proposal.](http://www.id3.org/Replay_Gain_Adjustment)
* [Hydrogen Audio thread about real-world support (or lack thereof) for RGAD.](http://www.hydrogenaudio.org/forums/index.php?showtopic=32745)
* [The home for MADplay, a freeware fixed-point MPEG decoder, which contains logic for decoding RGAD frames.](http://www.underbit.com/products/mad/)
* [The source for getid3, a PHP ID3v2 parsing library (search for 'RGAD').](http://getid3.sourceforge.net/source/module.tag.id3v2.phps)

iTunNORM
--------

* ["Definitive" reverse-engineering of iTunNORM values from flac2mp3 project.](http://projects.robinbowes.com/flac2mp3/trac/ticket/30)
* [Amusing guesses about what the unknown values in the iTunNORM comment denote.](http://forums.mp3tag.de/index.php?showtopic=8912#entry35486)
* [id3.org summary of iTunNORM values.](http://www.id3.org/iTunes_Normalization_settings)
* [Semi-useful Perl code for translating between iTunNORM values and dB adjustments.](http://svn.slimdevices.com/slim/7.4/trunk/server/Slim/Utils/SoundCheck.pm?revision=23955&view=markup)
* [Description of iTunNORM by the author of ipod2rg.](http://www.hydrogenaudio.org/forums/index.php?showtopic=24620)
* [Occasionally inaccessible site with Python code that calculates album gain and stores it in Soundcheck values.](http://media.scottr.org/album_soundcheck.py)

mp3gain APE tag
---------------

* [Discussion of mp3gain's use of APE tags.](http://www.hydrogenaudio.org/forums/index.php?showtopic=19576)
* [mp3gain FAQ, which baldly states that APE frames hold the gain values. Not very useful.](http://mp3gain.sourceforge.net/faq.php)

mp3gain TXXX
------------

* [mp3gainFAQ, again, which lists the replaygain field names.](http://mp3gain.sourceforge.net/faq.php)
* [Discussion of Sean Booth's Play's support for TXXX replay gain frames.](http://forums.sbooth.org/viewtopic.php?f=12&t=1938)
* [Another discussion from the Play forums.](http://forums.sbooth.org/viewtopic.php?f=14&t=1119)
* [Hydrogen Audio thread that led to the creation of foobar2k's TXXX-field replay gain support.](http://www.hydrogenaudio.org/forums/index.php?showtopic=19576)
