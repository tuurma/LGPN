xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://lgpn.classics.ox.ac.uk/apps/lgpn/config" at "config.xqm";
(:import module namespace names="http://www.existsolutions.com/apps/lgpn/names" at "names.xql";:)
(:import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";:)
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(: Switch to JSON serialization :)
declare option output:method "json";
declare option output:media-type "text/javascript";

(:draw=37:)
(:columns%5B0%5D%5Bdata%5D=0:)
(:columns%5B0%5D%5Bname%5D=:)
(:columns%5B0%5D%5Bsearchable%5D=true:)
(:columns%5B0%5D%5Borderable%5D=true:)
(:columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=:)
(:columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false:)
(:order%5B0%5D%5Bcolumn%5D=2:)
(:order%5B0%5D%5Bdir%5D=asc:)
(:start=0:)
(:length=50:)
declare function local:orderBy($index, $dir) {
    let $direction := if ($dir='desc') then ' descending' else ()
let $c:= console:log($index)

            let $po: =" $config:places//id($i//tei:state[@type='location'][1]/tei:placeName/@key)/tei:placeName[1]"
            let $ro: =" collection($config:persons-root)//id($i/ancestor::tei:body//tei:relation[1]/@passive)//tei:nym[1]/@nymRef"
(:                let $name := collection($config:persons-root)//tei:person[@xml:id=$relation/@passive]//tei:nym/@nymRef/string():)
                
    let $orderBy :=
    switch($index)
    case 0
        return "$i//tei:nym[1]/@nymRef"
    case 1
        return $po
    case 3
        return $ro
(:    case 8:)
(:        return "$i/parent::tei:entry//tei:m[@type='radical'][@n='1'][1]":)
    case 4
        return "xmldb:last-modified(util:collection-name($i), util:document-name($i))"
    default
        return "xmldb:last-modified(util:collection-name($i), util:document-name($i))"
(:        return "root($i)//tei:change[last()]/@when":)
(:        return 'replace($i/parent::tei:entry//tei:orth[@type="greek"][1],  "[\p{M}\p{Sk}]", "")' :)


    let $collation:= 
        switch($index)
            case 0
                return ' collation "?lang=el-grc&amp;amp;strength=primary&amp;amp;decomposition=standard"' 
            default 
                return ()

let $c:= console:log('ψολλατιον' || $collation)
        
    return $orderBy || $direction || $collation
    
    
};

declare function local:bibl($bibl) {
  let $text:= if ($bibl/@type eq 'primary') then 
        string-join(($bibl/tei:ref/@target, if($bibl/tei:ref/string()) then $bibl/tei:ref/string() else ()), ' ')
    else 
        string-join(($bibl/tei:ref/@target, if($bibl/tei:seg[@type='details']/string()) then $bibl/tei:seg[@type='details']/string() else ()), ' ')

  let $prefix :=
    switch ($bibl/@ana)
        case "equal" return '('
        case "published-twice" return '='
        case "correction" return '&amp;'
        default return ()
    
    let $sufix :=
    switch ($bibl/@ana)
        case "equal" return ')'
        default return ()

  (:    ;= book: =:)
(:= book: ():)
(:+ book: &:)
    return string-join(($prefix, $text, $sufix), '')
};

(:let $setuser :=  login:set-user("org.exist.lgpn-ling", (), false()):)
let $setuser := 'michael'

(:let $search := request:get-parameter('search', ''):)
let $search := if (request:get-parameter('search[value]', '')) then request:get-parameter('search[value]', '') else ''

let $recordsTotal := count(collection($config:persons-root)//tei:person)

let $start := number(request:get-parameter('start', ''))
let $length := number(request:get-parameter('length', ''))

let $end := if($length>0) then ($start + $length) else $recordsTotal

let $ordInd := request:get-parameter('order[0][column]', '1')
let $ordDir := request:get-parameter('order[0][dir]', 'asc')

let $draw := request:get-parameter('draw', '1')

(:let $offset :=     if (request:get-attribute("org.exist.lgpn-ling.user")) then 0 else -1:)
let $offset := 0

let $qs := replace(normalize-unicode(upper-case($search), "NFD"), "[\p{M}\p{Sk}]", "")

(: search also in place names :)
let $places:= if ($qs) then collection($config:places-root)//tei:placeName[contains(replace(normalize-unicode(upper-case(.), "NFD"), "[\p{M}\p{Sk}]", ""), $qs)]/parent::tei:place else ()
let $qp := if($places) then ' or .//tei:placeName/@key=("' || string-join($places/@xml:id, '", "') || '") ' else ''

(: search in nym/@nymRef attributes :)
let $nyms := if($qs) then 
    ' or .//tei:nym[contains(upper-case(normalize-unicode(@nymRef, "NFD")), "' || $qs || '")]  
     or .//tei:nym[contains(upper-case(replace(normalize-unicode(@nymRef, "NFD"), "[\p{M}\p{Sk}]", "")), "' || $qs || '")] ' 
    else ''

(: search in modification dates :)
let $dates := if($qs) then ' or ./ancestor::tei:TEI//tei:change[starts-with(@when, "' || $qs || '")]' else ''
    
(: search in references :)
let $refs := if($qs) then ' or .//tei:bibl[@type=("primary", "auxiliary")][contains(concat(tei:ref/@target, " ", tei:ref), "' || $search || '")]' else ''

let $collection := 'collection($config:persons-root)//tei:person'
||
'[@xml:id="'|| $search || '"
or 
contains(upper-case(normalize-unicode(., "NFD")), "'|| $qs || '") 
            or 
        contains(upper-case(replace(normalize-unicode(., "NFD"), "[\p{M}\p{Sk}]", "")), "' || $qs || '")'
        || $qp || $nyms || $dates || $refs || '
]
'


let $roff:=$offset+number($ordInd)
let $c:=console:log($roff)
let $orderby := local:orderBy($offset+number($ordInd), $ordDir)

(:  let $c:= console:log($ordInd || ' ' || $ordDir):)


    let $query :=
    '
    for $i in ' || $collection ||
    ' order by ' || $orderby ||
    ' return $i'
  
  let $c:= console:log($query || $qp)
    
    let $selection := util:eval($query)
    let $lang:=request:get-parameter('lang', 'en')
    
    let $results :=
    for $i in subsequence($selection, $start, $end)
        let $n := data($i//tei:nym/@nymRef)
        let $icon := <a>
        {attribute href {'editor.xhtml?id='|| $i/@xml:id}}
         <span class="glyphicon glyphicon-edit"/>
        </a>
        let $nlabel := <a>
        {attribute href {'editor.xhtml?id='|| $i/@xml:id}}
        {$n}
        </a>
        
        let $name := <span>{$icon}{$nlabel}</span>
        let $volume := $i//tei:bibl[@type='volume']/tei:ref/@target/string()
        let $date := if ($i//tei:birth/@when/string()) then $i//tei:birth/@when/string() else concat($i//tei:birth/@notBefore/string(), '-', $i//tei:birth/@notAfter/string())
        let $refs := 
            for $p in $i//tei:bibl
(:            [@type=('primary', 'auxiliary')]:)
                return if ($p/@type=('primary', 'auxiliary')) then local:bibl($p) else ()
        
        let $place := 
            for $p in $i//tei:state[@type='location']/tei:placeName/@key
                return string-join($config:places//id($p)/tei:placeName[@subtype ne 'minor'], '-')
                
        let $rels := 
            for $relation in $i/ancestor::tei:body//tei:relation
                let $name := collection($config:persons-root)//tei:person[@xml:id=$relation/@passive]//tei:nym/@nymRef/string()
                let $link := doc($config:app-root || "/resources/xml/relationships.xml")//option[@value=$relation/@name/string()]/string()
            return
                        if($relation/@passive/string()) then
         <a>
        {attribute href {'editor.xhtml?id='|| $relation/@passive}}
        {string-join(($link, $name), ' ')}
        </a> else ()

        let $clipboard :=   <button class="clipboard" data-clipboard-text="{$i/@xml:id}">
                                <img src="resources/img/clippy.svg" alt="Copy to clipboard" height="20"/>
                            </button>

        let $u := if($i) then xmldb:last-modified(util:collection-name($i), util:document-name($i)) else ()
        let $updated := <span>{substring-before($u, 'T')}<span class="invisible">{$u}</span></span>


        return 
    map:new( 
            (

                
(:                if($offset=0) then map:entry(0, names:entry-action($i, '')) else (),:)
                map:entry(0, $name),
                map:entry(1, $volume),
                map:entry(2, $place),
                map:entry(3, $date),
                map:entry(4, string-join($refs, '; ')),
                map:entry(5, $rels),
                map:entry(6, $updated),
                map:entry(7, $clipboard)
(:                ,:)
(:                map:entry($offset+18, names:entry-updated($i)),:)
(:                if($offset=0) then map:entry($offset+19, names:entry-action($i, 'delete')) else ():)
            )
    )

let $recordsFiltered := count($selection)

		return map {
			"draw" := $draw,
			"recordsTotal"    :=  $recordsTotal,
			"recordsFiltered" :=  $recordsFiltered,
			"data"            := if(count($results)>1) then $results else array{$results} 
		}
