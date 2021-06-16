function smessage_tab(method,tool) {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {method:method,tool:tool});
        });
}
let view,prev,button,discription,tool,allarr=[],id,ready,n=0;
//-------------------------------------------------------------------

function opening() {
    let windows = chrome.extension.getViews({type: "popup"})
    view = windows[0];
    button = view.document.getElementById("button");
    discription = view.document.getElementById("discription");   
}
function show_hide(one,two) {
    view.document.getElementById("tools").style.display=one;
    view.document.getElementById("operate").style.display=two;
}
function button_clicked(){ 
    if(button.value=="RUN"){smessage_tab("calling",tool);name_color("CANCLE","#fb8500","running.. to abort task press cancle")}
    else if(button.value=="CANCLE"){smessage_tab("code","window.location.reload()");name_color("RUN","#8ecae6","click run to scrape")}
    else if(button.value=="LATER"){prev="";tool="";show_hide("block","none")}       
}
function button_changed(message){ 
    prev = message || prev;
    if(prev=="start"){name_color("RUN","#8ecae6","click run to scrape")}
    else if(prev=="running"){name_color("CANCLE","#fb8500","running.. to abort task press cancle")}
    else if(prev=="finished"){name_color("LATER","#ffb703","results are stored, you can save it later with other results combined, once download button clicked results will 'ERASE'.")}     
}
function name_color(name,color,text) {
    if(name!=""){
        button.value=name;
        button.style.backgroundColor=color;
    }
    discription.innerText=text
}
function store(message){
    allarr.push.apply(allarr,message)
}
function download_file(data) {
    var blob = new Blob([data], {type: 'text/csv'});
    var elem = window.document.createElement('a');
    elem.href = window.URL.createObjectURL(blob);
    elem.download = "scrap_result.txt";        
    document.body.appendChild(elem);
    elem.click();        
    document.body.removeChild(elem);
    allarr=[];
}
function spider(act) {
    if(act=="create"){
        ready=true;
        let link=["https://coolors.co/palettes/trending","https://google.com"];
        if(link[n]){
            chrome.tabs.create({url:link[n]},function (tabs) {id=tabs.id})
            n++;
            }else{
                n=0;
            }
    }
        /*let wait1=async ()=>{
            while(true){
                if(ready){
                    console.log("yes send")
                    //chrome.tabs.sendMessage(tabs.id, {method:"calling",tool:"id"});
                    ready=false;
                    break;
                }else{
                    console.log("waiting....")
                    await new Promise(resolve =>{setTimeout(() => {resolve()}, 2000)})
                }       
            }}*/
        //wait1();
    else if(act=="send"){
        //console.log("yes send")
        chrome.tabs.sendMessage(id, {method:"calling",tool:"id"});
        ready=false;
    }
}

//---------------------------------------------------------------
function popup_called(method,message){ 
    if(method=="call_background"){
        opening()
        if(!tool||!prev){show_hide("block","none")}
        else{button_changed()}    
    }
    else if(method=="tool"){
        tool=message;
        show_hide("none","block")
        if(tool=="SPIDER"){spider("create")}
    }
    else if(method=="button_clicked"){
        button_clicked();
    }
    else if(method=="button_changed"){
        button_changed(message);
    }
    else if(method=="store"){
        store(message)
    }
    else if(method=="download"){
        if(allarr.length==0){
            return name_color("","","No results to download")
        }
        download_file(allarr.join(",").replaceAll(",","\n"));
        tool="";
        prev=""
        name_color("RUN","#8ecae6","click run to scrape")
    }
    else if(method=="ready"){
        if(ready){
            spider("send")}
        }
}


//-----------------------listion message----------------------
chrome.runtime.onMessage.addListener(
    function(request, sender, sendResonsep) {
        popup_called(request.method,request.message)
    });
