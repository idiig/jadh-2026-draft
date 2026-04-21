#let _ = ```typ
exec typst c "$0" --root "$(readlink -f "$0" | xargs dirname)/./" --input file-0=/example.svg
⁠```
#set document(title: "Kugire Data Curation for the Kokinwakashu TEI/XML Data", author: "idg")
#set text(lang: "en")
#set heading(numbering: "1.")
#set page(
  paper: "a4",
  width: 210mm,
  height: 297mm,
  columns: 1,
  numbering: "1"
)

#show figure: set align(left)

// Paragraph settings
#set par(
  leading: 0.8em,    // line spacing
  spacing: 1.2em,    // paragraph spacing
)

// Heading spacing
#show heading: set block(above: 3em, below: 1.5em)

// List spacing
#show list: set block(above: 1.2em, below: 1.2em)
#set list(spacing: 1.2em)

// Enumeration spacing
#show enum: set block(above: 1.2em, below: 1.2em)
#set enum(spacing: 1.2em)

// Figure and table spacing
#show figure: set block(above: 1.2em, below: 1.2em)
#set figure(placement: auto)

// Sty
#import "@preview/toffee-tufte:0.1.0": *

#align(center)[
  #set text(size: 18pt)
  Kugire Data Curation for the Kokinwakashu TEI/XML Data
]
#heading(level: 1)[Introduction] #label("org349fece")
Kugire — phrase breaks within waka poems — are a basic structural element of waka, yet no standardized, publicly available kugire dataset exists (#link(label("org92e93b9"))[Kami, 1985]). For TEI\u{2f}XML encoding of waka, each project must annotate from scratch.

#link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem")[atuko315\u{2f}program\u{2d}to\u{2d}divide\u{2d}31\u{2d}syllable\u{2d}Japanese\u{2d}poem] #footnote(link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem")) is one of the few existing kugire resources: a program to identify kugire with a dataset for the Hyakuninisshu, later applied to the Kokinwakashu and compared against Asaoka (#link(label("orge61c803"))[2008]) and Kami (#link(label("org92e93b9"))[1985]). The dataset, however, cannot capture the interpretive nature of kugire, which admits no single correct answer. Asaoka (#link(label("org1ecefc0"))[2007]) proposes two criteria — semantic independence of core sentences (necessary) and a clear grammatical break (sufficient) — both of which remain open to interpretation. A kugire dataset should therefore collect annotations from multiple sources, each with documented criteria.

This project adds kugire as an interpretive annotation layer to the TEI\u{2f}XML data of the Kokinwakashu, using rule\u{2d}based and translation\u{2d}based methods. Keeping kugire as a separate layer preserves the annotation criteria and any competing interpretations. The data supports analysis of waka structure, enjambment, diachronic change of kugire position, and its relation to poetic style.
#heading(level: 1)[Data sources] #label("org2c008c7")
#heading(level: 2)[Base data] #label("orgfa7e30b")
The base data is a lexically extended version of the TEI data of the Karoku second\u{2d}year manuscript of the Kokinwakashu (#link(label("org4f9a9dc"))[Ikuura et al., 2023]). The extended dataset maps tokenization from the Hachidaishu Vocabulary Dataset (#link(label("org504e299"))[Hodošček and Yamamoto, 2022]) onto this segmented text, forming the basis for the kugire annotation.
#heading(level: 2)[Reference data] #label("org07b8832")
For the rule\u{2d}based method, we use the Hachidaishu Part\u{2d}of\u{2d}Speech Dataset (#link(label("org1873573"))[Yamamoto et al., 2024a]), which provides conjugation and part\u{2d}of\u{2d}speech data for each token. For the translation\u{2d}based method, we use the explanatory translation of the Kokinwakashu by (#link(label("org24d292a"))[Kaneko, 1933]), the earliest twentieth\u{2d}century explanatory translation of the anthology, digitized and published on Zenodo (#link(label("orgc4cf895"))[Yamamoto et al., 2024b]).
#heading(level: 1)[Output Data] #label("orge2e0dd7")
The output is #raw("kokin-kugire.xml"), a TEI\u{2f}XML file derived from the base data by appending kugire annotations to each poem. The original text, segmentation, and all existing TEI markup are preserved without modification; the annotation layer is additive.

Each kugire position is encoded as a #raw(block: false, "<k>") element placed after the final #raw(block: false, "<seg>") child of the corresponding line element #raw(block: false, "<l>"):

#figure(
  [
```xml
<l n="1" xml:id="n1">
  <seg>年の内に</seg>
  <seg>春はきにけり</seg>
  <seg>ひとゝせを</seg>
  <seg>こそとやいはむ</seg>
  <seg>ことしとやいはむ</seg>
  <k n="2" source="morph" cert="high"/>
  <k n="3" source="morph" cert="low"/>
  <k n="4" source="morph" cert="high"/>
  <k n="2" source="kaneko"/>
</l>
```
  ],
  caption: [TEI\u{2f}XML encoding of kugire annotations for poem 1 of the Kokinwakashu. Each #raw(block: false, "<k>") element marks a candidate break position. Morphological candidates carry a three\u{2d}level certainty grade (#raw(block: false, "cert"): #raw(block: false, "high"), #raw(block: false, "mid"), #raw(block: false, "low")); translation\u{2d}based candidates (#raw(block: false, "source=\u{22}kaneko\u{22}")) carry none.],
  kind: image,
  placement: none
)

The rule\u{2d}based method identifies three candidate positions. The
strongest (#raw(block: false, "cert=\u{22}high\u{22}")) is after the second segment, where #emph[keri]
appears in the conclusive form, ending the first complete sentence. A
weaker candidate (#raw(block: false, "cert=\u{22}low\u{22}")) is also placed after the third
segment. The LLM\u{2d}assisted translation\u{2d}based method, drawing on
explanatory translation (#link(label("org24d292a"))[Kaneko, 1933]), identifies
only the second segment as a kugire. The competing candidates are
preserved independently.

The #raw("@n") attribute is the 1\u{2d}based segment index; #raw("@source") is the evidence code; #raw("@cert") (#raw("high") \u{2f} #raw("mid") \u{2f} #raw("low")) grades morphological certainty for rule\u{2d}based annotations and is omitted for translation\u{2d}based ones.

Multiple #raw("<k>") elements at the same position represent competing interpretations — from the same source at different grammatical strengths, or from different sources — and are preserved as\u{2d}is. No normalization or deduplication is applied.

The #raw("<k>") element is a project\u{2d}internal tag pending a decision on the target TEI encoding.
#heading(level: 1)[Annotation pipeline] #label("org440656b")
The annotation follows an LLM\u{2d}assisted pipeline:

#enum(enum.item(1)[Rule\u{2d}based suggestion of candidate kugire positions based on Yamamoto et al. (#link(label("org1873573"))[2024a])],
enum.item(2)[LLM\u{2d}assisted translation\u{2d}based suggestion of candidate kugire positions based on Kaneko (#link(label("org24d292a"))[1933]; #link(label("orgc4cf895"))[Yamamoto et al., 2024b])],
enum.item(3)[Review and correction in a pop\u{2d}up editor showing the original poem and its reference data],
enum.item(4)[Rendering the confirmed annotation into the TEI data],
)

The pipeline accelerates the annotation process. The per\u{2d}poem review cycle reduces cognitive load and improves accuracy.
#heading(level: 2)[Rule\u{2d}based (grammar\u{2d}wise) kugire suggestion] #label("org274708b")
Our method extends the program#footnote[#link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem").], which flags conclusive forms, copulas, and sentence\u{2d}final particles as kugire, by outputting graded candidates — strong, moderate, and weak — rather than a single result.

Strong candidates are phrases ending in the conclusive form. For example, in the first poem of the Kokinwakashu, the past\u{2d}tense auxiliary verb #emph[keri] appears in the conclusive form, indicating a grammatical break after it (#ref(label("org2433f06"))\u{2d}(1)).

#figure([#image(sys.inputs.file-0)], caption: [Three types of kugire annotation derived from morphological analysis: (1) strong, (2) moderate, and (3) weak candidates. Glossing follows Zisk (#link(label("org9c784da"))[2023]).]) #label("org2433f06")

Moderate candidates are phrases where the copula or information structure suggests a break, though not conclusively. In the second poem of the Kokinwakashu, the segments before and after #raw("wo") are syntactically connected, yet the former presents a scene while the latter offers a conjectural statement about it — a shift that may indicate a break (#ref(label("org2433f06"))\u{2d}(2)).

Weak candidates are phrases where a sentence\u{2d}final particle suggests a break, but the surrounding segments remain semantically interdependent. In the third poem of the Kokinwakashu, the question particle in the second segment may suggest a break, yet the following segment answers that question — semantic interdependence that makes the break uncertain (#ref(label("org2433f06"))\u{2d}(3)).
#heading(level: 2)[LLM\u{2d}assisted translation\u{2d}based kugire suggestion] #label("orgf48f711")
We also use a large language model (LLM) to suggest candidate kugire positions from the explanatory translation of (#link(label("org24d292a"))[Kaneko, 1933]) as encoded by (#link(label("orgc4cf895"))[Yamamoto et al., 2024b]). Where the rule\u{2d}based approach draws on morphological and grammatical features, the LLM\u{2d}assisted translation\u{2d}based approach draws on the contemporary Japanese translation, capturing breaks rooted in the translator\u{27}s reading rather than grammatical form alone.

The LLM is #raw("qwen2.5"), served locally via Ollama. The model receives the five segments of the original poem and the corresponding explanatory translation, and outputs a JSON object with three fields: #raw("alignment") (step 1), #raw("breaks") (step 2), and #raw("positions") (the resulting candidate indices).

The prompt instructs the model to align segments to the translation, detect sentence boundaries in the translation, and map them back to segment positions — mirroring the workflow of a human annotator using a translation as reference. Three few\u{2d}shot examples from real Kokinwakashu poems demonstrate this chain, covering no\u{2d}kugire, second\u{2d}segment, and fourth\u{2d}segment cases. Valid positions from the JSON output are recorded independently of rule\u{2d}based results, e.g., #raw(block: false, "<k n=\u{22}2\u{22} source=\u{22}kaneko\u{22}/>").
#heading(level: 1)[Conculusion] #label("orgb2f1a0e")
This project produced a TEI\u{2f}XML dataset prototype of kugire annotations for the Kokinwakashu, derived from a lexically extended base and informed by both rule\u{2d}based and LLM\u{2d}assisted translation\u{2d}based methods. The dataset preserves multiple interpretations of kugire, supporting analysis of waka structure and diachronic change. 
#heading(level: 1)[References] #label("org510384d")
 #label("orge61c803")​#text(weight: "bold", [Asaoka Sumiaki 浅岡純朗.]) (2008). Waka ni Okeru Bun no Kosei: Heian Waka no Tenkanki ni Kansuru Ichi Kosatsu\u{2f}Sentence Structure in Waka: A Study on the Transitional Period of Heian Waka [和歌における文の構成―平安和歌の転換期に関する一考察―]. #emph[Nishogakusha Daigaku Jinbun Ronsoˉ\u{2f}Nishogakusha University Journal of Humanities], #text(weight: "bold", [81]), pp. 130–40.

 #label("org1ecefc0")​#text(weight: "bold", [Asaoka Sumiaki 浅岡純朗.]) (2007). Waka no Kugire ni Kansuru Ichi Kosatsu: Atarashii Nintei Kijun Shian no Koso\u{2f}A Study on Kugire in Waka: Toward a New Proposal for Recognition Criteria [和歌の句切れに関する一考察 : 新しい認定基準私案の構想]. #emph[Nishogakusha Daigaku Jinbun Ronsoˉ\u{2f}Nishogakusha University Journal of Humanities], #text(weight: "bold", [78]), pp. 113–22.

 #label("org504e299")​#text(weight: "bold", [Hodošček, B. and Yamamoto, H.]) (2022). Development of Datasets of the Hachidaishū and Tools for the Understanding of the Characteristics and Historical Evolution of Classical Japanese Poetic Vocabulary. In #emph[Digital Humanities 2022 Conference Abstracts]. Tokyo, Japan.

 #label("org4f9a9dc")​#text(weight: "bold", [Ikuura Hiroyuki 幾浦裕之., Nagasaki Kiyonori 永崎研宣. and Kato Yumie 加藤弓枝.]) (2023). Chokusen Wakashu no Kozo\u{2d}ka to Teiji Shuho ni Kansuru Kokoromi: Karoku Ninenhon Kokinwakashu wo Jirei to shite\u{2f}An Attempt at Structuring and Presenting Imperial Waka Anthologies: The Karoku Second\u{2d}Year Manuscript of the Kokinwakashu as a Case Study [勅撰和歌集の構造化と提示手法に関する試み ―嘉禄二年本『古今和歌集』を事例として―]. In #emph[Proceedings of JINMONCOM 2023]. Information Processing Society of Japan, pp. 183–90.

 #label("org92e93b9")​#text(weight: "bold", [Kami Hiroyuki 紙宏行.]) (1985). Shin\u{2d}Kokin ni Okeru Sankugire no Hyogen Kozo\u{2f}The Expressive Structure of Third\u{2d}Line Breaks in the Shin\u{2d}Kokinshū [新古今における三句切れの表現構造]. #emph[Bunkyo Daigaku Joshi Tandai\u{2d}bu Kenkyu Kiyo\u{2f}Bunkyo University Women’s College Bulletin], #text(weight: "bold", [29]), pp. 10–23.

 #label("org24d292a")​#text(weight: "bold", [Kaneko Motoomi 金子元臣.]) (1933). #emph[Kokinwakashu Hyoshaku: Showa Shimban\u{2f}An Annotated Kokinwakashu: The New Showa Edition [古今和歌集評釈: 昭和新版]]. Tokyo: Meijishoin.

 #label("org1873573")​#text(weight: "bold", [Yamamoto, H., Hodošček, B. and Chen, X.]) (2024a). Hachidaishu Part\u{2d}of\u{2d}Speech Dataset. #link("https://doi.org/10.5281/zenodo.13940187")[10.5281\u{2f}zenodo.13940187] #footnote(link("https://doi.org/10.5281/zenodo.13940187")).

 #label("orgc4cf895")​#text(weight: "bold", [Yamamoto, H., Hodošček, B. and Chen, X.]) (2024b). Kokinwakashu Hyoshaku by Motoomi Kaneko Translation Sentence Vocabulary Dataset. #link("https://doi.org/10.5281/zenodo.13942707")[10.5281\u{2f}zenodo.13942707] #footnote(link("https://doi.org/10.5281/zenodo.13942707")).

 #label("org9c784da")​#text(weight: "bold", [Zisk, M.]) (2023). Glossing Glosses: Methods for Transcribing and Glossing Japanese Kundoku Texts. In Cinato, F.Lahaussois, A.and Whitman, J.B. (eds), #emph[Glossing Practice, Comparative Perspectives]. Lexington Books, pp. 47–82.
