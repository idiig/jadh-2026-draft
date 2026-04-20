#let _ = ```typ
exec typst c "$0" --root "$(readlink -f "$0" | xargs dirname)/./" --input file-0=/example.svg
⁠```
#set document(title: "Kugire Data Curation for the Kokinwakashu TEI/XML Data", author: "idg")
#set text(lang: "en")
#outline()
#set heading(numbering: "1.")
#set page(
  paper: "a4",
  width: 210mm,
  height: 297mm,
  columns: 1
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

// Sty
#import "@preview/toffee-tufte:0.1.0": *

#align(center)[
  #set text(size: 18pt)
  Kugire Data Curation for the Kokinwakashu TEI/XML Data
]
#heading(level: 1)[Introduction] #label("org26bbfd2")
Kugire — phrase breaks within waka poems — are a basic structural element of waka, yet no standardized, publicly available kugire dataset exists #link(label("org67014f6"))[[1]]. For TEI\u{2f}XML encoding of waka, each project must annotate from scratch.

#link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem")[atuko315\u{2f}program\u{2d}to\u{2d}divide\u{2d}31\u{2d}syllable\u{2d}Japanese\u{2d}poem] #footnote(link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem")) is one of the few existing kugire resources: a program to identify kugire with a dataset for the Hyakuninisshu, later applied to the Kokinwakashu and compared against #link(label("org7eebb85"))[[2]] and #link(label("org67014f6"))[[1]]. The dataset, however, cannot capture the interpretive nature of kugire, which admits no single correct answer. #link(label("org718bdd5"))[[3]] proposes two criteria — semantic independence of core sentences (necessary) and a clear grammatical break (sufficient) — both of which remain open to interpretation. A kugire dataset should therefore collect annotations from multiple sources, each with documented criteria.

This project adds kugire as an interpretive annotation layer to the TEI\u{2f}XML data of the Kokinwakashu, using rule\u{2d}based and translation\u{2d}based methods. Keeping kugire as a separate layer preserves the annotation criteria and any competing interpretations. The data supports analysis of waka structure, enjambment, diachronic change of kugire position, and its relation to poetic style.
#heading(level: 1)[Data sources] #label("orgada37ce")
#heading(level: 2)[Base data] #label("orga5590fc")
The base data is a lexically extended version of the TEI data of the Karoku second\u{2d}year manuscript of the Kokinwakashu #link(label("org96d61a1"))[[4]]. The extended dataset maps tokenization from the Hachidaishu Vocabulary Dataset #link(label("org33a5280"))[[5]] onto this segmented text, forming the basis for the kugire annotation.
#heading(level: 2)[Reference data] #label("orgda608d7")
For the rule\u{2d}based method, we use the Hachidaishu Part\u{2d}of\u{2d}Speech Dataset #link(label("org7fce53a"))[[6]], which provides conjugation and part\u{2d}of\u{2d}speech data for each token. For the translation\u{2d}based method, we use the explanatory translation of the Kokinwakashu by #link(label("orgab24862"))[[7]], the earliest twentieth\u{2d}century explanatory translation of the anthology, digitized and published on Zenodo #link(label("org2338293"))[[8]].
#heading(level: 1)[Output Data] #label("org0f3ff17")
The output is #raw("kokin-kugire.xml"), a TEI\u{2f}XML file derived from the base data by appending kugire annotations to each poem. The original text, segmentation, and all existing TEI markup are preserved without modification; the annotation layer is additive.

Each kugire position is encoded as a #raw(block: false, "<k>") element placed after the final #raw(block: false, "<seg>") child of the corresponding line element #raw(block: false, "<l>"):

The rule\u{2d}based method identifies three candidate positions. The
strongest (#raw(block: false, "cert=\u{22}high\u{22}")) is after the second segment, where #emph[けり]
appears in the conclusive form, ending the first complete sentence. A
weaker candidate (#raw(block: false, "cert=\u{22}low\u{22}")) is also placed after the third
segment. The LLM\u{2d}assisted translation\u{2d}based method, drawing on
explanatory translation #link(label("orgab24862"))[[7]], identifies
only the second segment as a kugire. The competing candidates are
preserved independently.

The #raw("@n") attribute is the 1\u{2d}based segment index; #raw("@source") is the evidence code; #raw("@cert") (#raw("high") \u{2f} #raw("mid") \u{2f} #raw("low")) grades morphological certainty for rule\u{2d}based annotations and is omitted for translation\u{2d}based ones.

Multiple #raw("<k>") elements at the same position represent competing interpretations — from the same source at different grammatical strengths, or from different sources — and are preserved as\u{2d}is. No normalization or deduplication is applied.

The #raw("<k>") element is a project\u{2d}internal tag pending a decision on the target TEI encoding.
#heading(level: 1)[Annotation pipeline] #label("orge9f7310")
The annotation follows an LLM\u{2d}assisted pipeline:

#enum(enum.item(1)[Rule\u{2d}based suggestion of candidate kugire positions based on #link(label("org7fce53a"))[[6]]],
enum.item(2)[LLM\u{2d}assisted translation\u{2d}based suggestion of candidate kugire positions based on #link(label("orgab24862"))[[7]], #link(label("org2338293"))[[8]]],
enum.item(3)[Review and correction in a pop\u{2d}up editor showing the original poem and its reference data],
enum.item(4)[Rendering the confirmed annotation into the TEI data],
)

The pipeline accelerates the annotation process. The per\u{2d}poem review cycle reduces cognitive load and improves accuracy.
#heading(level: 2)[Rule\u{2d}based (grammar\u{2d}wise) kugire suggestion] #label("org6230d71")
Our method extends the program#footnote[#link("https://github.com/atuko315/program-to-divide-31-syllable-Japanese-poem").], which flags conclusive forms, copulas, and sentence\u{2d}final particles as kugire, by outputting graded candidates — strong, moderate, and weak — rather than a single result.

Strong candidates are phrases ending in the conclusive form. For example, in the first poem of the Kokinwakashu, the past\u{2d}tense auxiliary verb #emph[keri] appears in the conclusive form, indicating a grammatical break after it (#ref(label("orgafdf3f4"))\u{2d}(1)).

#figure([#image(sys.inputs.file-0)]) #label("orgafdf3f4")

Moderate candidates are phrases where the copula or information structure suggests a break, though not conclusively. In the second poem of the Kokinwakashu, the segments before and after #raw("wo") are syntactically connected, yet the former presents a scene while the latter offers a conjectural statement about it — a shift that may indicate a break (#ref(label("orgafdf3f4"))\u{2d}(2)).

Weak candidates are phrases where a sentence\u{2d}final particle suggests a break, but the surrounding segments remain semantically interdependent. In the third poem of the Kokinwakashu, the question particle in the second segment may suggest a break, yet the following segment answers that question — semantic interdependence that makes the break uncertain (#ref(label("orgafdf3f4"))\u{2d}(3)).
#heading(level: 2)[LLM\u{2d}assisted translation\u{2d}based kugire suggestion] #label("org8eaeb0a")
We also use a large language model (LLM) to suggest candidate kugire positions from the explanatory translation of [kaneko] as encoded by [yamamoto]. Where the rule\u{2d}based approach draws on morphological and grammatical features, the LLM\u{2d}assisted translation\u{2d}based approach draws on the contemporary Japanese translation, capturing breaks rooted in the translator\u{27}s reading rather than grammatical form alone.

The LLM is #raw("qwen2.5"), served locally via Ollama. The model receives the five segments of the original poem and the corresponding explanatory translation, and outputs a JSON object with three fields: #raw("alignment") (step 1), #raw("breaks") (step 2), and #raw("positions") (the resulting candidate indices).

The prompt instructs the model to align segments to the translation, detect sentence boundaries in the translation, and map them back to segment positions — mirroring the workflow of a human annotator using a translation as reference. Three few\u{2d}shot examples from real Kokinwakashu poems demonstrate this chain, covering no\u{2d}kugire, second\u{2d}segment, and fourth\u{2d}segment cases. Valid positions from the JSON output are recorded independently of rule\u{2d}based results, e.g., #raw(block: false, "<k n=\u{22}2\u{22} source=\u{22}kaneko\u{22}/>").
#heading(level: 1)[Conculusion] #label("org93f96be")
This project produced a TEI\u{2f}XML dataset prototype of kugire annotations for the Kokinwakashu, derived from a lexically extended base and informed by both rule\u{2d}based and LLM\u{2d}assisted translation\u{2d}based methods. The dataset preserves multiple interpretations of kugire, supporting analysis of waka structure and diachronic change. 
#heading(level: 1)[References] #label("org16b864f")
 [1] #label("org67014f6") 紙 宏行, “新古今における三句切れの表現構造,” #emph[文教大女子短大部研究紀要], vol. 29, pp. 10–23, Dec. 1985.

 [2] #label("org7eebb85") 浅岡 純朗, “和歌における文の構成―平安和歌の転換期に関する一考察―,” #emph[二松学舎大学人文論叢], vol. 81, pp. 130–140, Oct. 2008.

 [3] #label("org718bdd5") 浅岡 純朗, “和歌の句切れに関する一考察 : 新しい認定基準私案の構想,” #emph[二松学舎大学人文論叢], vol. 78, pp. 113–122, Mar. 2007.

 [4] #label("org96d61a1") 幾浦 裕之, 永崎 研宣, and 加藤 弓枝, “勅撰和歌集の構造化と提示手法に関する試み ―嘉禄二年本『古今和歌集』を事例として―,” #emph[じんもんこん2023論文集], vol. 2023, pp. 183–190, Dec. 2023.

 [5] #label("org33a5280") B. Hodošček and H. Yamamoto, “Development of datasets of the Hachidaishū and tools for the understanding of the characteristics and historical evolution of classical Japanese poetic vocabulary.:,” 2022.

 [6] #label("org7fce53a") H. Yamamoto, B. Hodošček, and X. Chen, “Hachidaishu Part\u{2d}of\u{2d}Speech Dataset.” Zenodo, Oct. 16, 2024, doi: #link("https://doi.org/10.5281/zenodo.13940187")[10.5281\u{2f}zenodo.13940187] #footnote(link("https://doi.org/10.5281/zenodo.13940187")).

 [7] #label("orgab24862") Kaneko Motoomi 金子元臣, #emph[Kokinwakashu hyoshaku: Showa shimban\u{2f}An annotated kokinwakashu: The new Showa edition [古今和歌集評釈: 昭和新版]]. Tokyo: Meijishoin, 1933.

 [8] #label("org2338293") H. Yamamoto, B. Hodošček, and X. Chen, “Kokinwakashu Hyoshaku by Motoomi Kaneko translation sentence vocabulary dataset.” Zenodo, Oct. 16, 2024, doi: #link("https://doi.org/10.5281/zenodo.13942707")[10.5281\u{2f}zenodo.13942707] #footnote(link("https://doi.org/10.5281/zenodo.13942707")).
