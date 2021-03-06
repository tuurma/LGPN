xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace config="http://lgpn.classics.ox.ac.uk/apps/lgpn/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(: Switch to JSON serialization :)
declare option output:method "json";
declare option output:media-type "text/javascript";


let $data := request:get-parameter('query', '')
            let $constituents :=  
                collection($config:persons-root)//tei:nym[starts-with(replace(lower-case(normalize-unicode(@nymRef, "NFD")), "[\p{M}\p{Sk}]", ""), replace(lower-case(normalize-unicode($data, "NFD")), "[\p{M}\p{Sk}]", ""))]
                |  
                collection($config:persons-root)//id($data)//tei:nym[1]
            return
            <result>
                <total>{count($constituents)}</total>
                { for $m in $constituents
                
                    let $parent_id := $m/root()//tei:relation[@name="child"][1]/@passive
                    let $parent := collection($config:persons-root)//id($parent_id)//tei:nym/@nymRef
                    let $place_id := $m/root()//tei:state/tei:placeName[1]/@key
                    let $place := if($place_id) then $config:places//tei:place[@xml:id=$place_id]/tei:placeName[1] else ()
                    let $ref := ($m/root()//tei:bibl[@type='primary'][1]/tei:ref, $m/root()//tei:bibl[@type='auxiliary'][1]/tei:ref)[1]
                    let $source := $ref/@target || ' ' || $ref/string()
                    let $date :=  xmldb:last-modified(util:collection-name($m), util:document-name($m))

                    order by $date descending, $m
                    return 
                    <term>
                        <id>{$m/@nymRef/string()} 
                        {if($parent) then ' child of ' || string-join($parent, ', ') else ()} 
                        {' ' || string-join($place)}
                        {' ' || $source}
                        </id>
                        <value>{$m/@nymRef/string()}</value>
                        <xformsValue>{$m/ancestor::tei:person/@xml:id/string()}</xformsValue>
                    </term>
                }
            </result>
