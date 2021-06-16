function smessage_tab(rtool) {
    chrome.tabs.query({active: true, currentWindow: true},async function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {tool:rtool},function (response) {
               var errr=chrome.runtime.lastError;
               if(errr){
                    m++;
                    if(m==50){return}
                    count.innerText="!Reload the page,if you already did wait till page load";
                    setTimeout(() => {
                        console.log("trying gain")
                       return smessage_tab(rtool);
                    }, 1000)
                }else{
                    if(tool=="SPIDER"&&!create_tab){temparr=allarr;return auto()}
                    if(tool=="COPY_URL"){return auto()}
                }
            });
        });
}
let view,button,tool,running,allarr=[],id,ready,n=0,m=0,filearr=[],temparr=[],grep_data=[],create_tab,url,count,page,domain;

//=========================================================================

function opening() {
    let windows = chrome.extension.getViews({type: "popup"})
    view = windows[0];
    count = view.document.getElementById("count");
    count2 = view.document.getElementById("count2");
    if(!tool){show_hide("block","none")}
    count.innerText=`${allarr.length} results are saved`;
    count2.innerText=`${allarr.length} results`;
}
function COPY_URL() {
    if(temparr.length==0){
        smessage_tab(tool);
    }else{
        var tempreg=new RegExp(`${domain}\/.+\\.js`)
        for(t=0;t<=temparr.length;t++){
            if(tempreg.test(temparr[t])){
                if(temparr[t].charAt(0)=='/'){
                    temparr[t]=url.match(/https*:\/\/[^\/]+/)[0]+temparr[t]
                }
                GREP_URL(temparr[t])
            }
                
        }
        temparr=[];
    }
}
async function FILE_URL(){
    if(filearr.length==0){
        try{
            let file=await window.showOpenFilePicker();
            let fread=await file[0].getFile();
            let txt=await fread.text();
            filearr=txt.split("\n");
        }catch(err){tool=false}
    }
    if(create_tab){smessage_tab(tool)}
    if(filearr.length!=0){
        if(filearr[n]){
            chrome.tabs.create({url:filearr[n]},function (tabs) {id=tabs.id});
            create_tab=true;
            n++;
        }else{
            n=0;
            create_tab=false;
            filearr=false;
            tool=false;
            running=false;
        }
    }   
}
function SPIDER(){
    if(temparr.length==0){
         smessage_tab(tool);  
    }
    if(temparr.length!=0){
        if(create_tab){smessage_tab(tool)}
        if(temparr[n]){
            if (temparr[n].charAt(0)=='/'&&!/\.(jpg|png|woff|woff2|svg|gif|css|pdf|mp4|webm|ico|webp|asc)$/.test(temparr[n])){
                temparr[n]=url.match(/https*:\/\/[^\/]+/)[0]+temparr[n]
                if(/https*:\/\/.*\..*\/+.*\.[a-zA-Z]+$/.test(temparr[n])&&!/\.(jpg|png|woff|woff2|svg|gif|css|pdf|mp4|webm|ico|webp|asc)$/.test(temparr[n])){
                    GREP_URL(temparr[n])
                }else{
                    var cill=temparr[n]
                }

            }else if(new RegExp(`${url.match(/https*:\/\/[^\/]+/)[0]}`).test(temparr[n])&&!/\.(jpg|png|woff|woff2|svg|gif|css|pdf|mp4|webm|ico|webp|asc)$/.test(temparr[n])){
                if(/https*:\/\/.*\..*\/+.*\.[a-zA-Z]+$/.test(temparr[n])&&!/\.(jpg|png|woff|woff2|svg|gif|css|pdf|mp4|webm|ico|webp|asc)$/.test(temparr[n])){
                    GREP_URL(temparr[n])
                }else{
                    cill=temparr[n];
                }
            }
            if(cill){   
                console.log(cill,n)
                chrome.tabs.create({url:cill},function (tabs) {id=tabs.id});
                create_tab=true;
                n++;
            }else{
                create_tab=false
                cill=false;
                n++;
                return auto()
            }
        }else{
            n=0;
            console.log("finished")
            create_tab=false;
            running=false;
            temparr=[];
        }
    }
}
async function GREP_URL(furl) {
    try{
        let i = await (await fetch(furl)).text()
        grep_data=i.match(/(?:https*:\/\/[a-zA-Z0-9\_\-]*\.*[a-zA-Z0-9\_-]{2,}\.(?:[a-z]{4}|[a-z]{3}|[a-z]{2})\/[^\'\"\<\>\;\,\ \: ]+)|(?:https*:\/\/[a-zA-Z0-9\_\-]*\.*[a-zA-Z0-9\_-]{2,}\.(?:[a-z]{4}|[a-z]{3}|[a-z]{2}))/g)
        if(grep_data.length!=0){return store(grep_data)}
    }catch(err){return}
}
function CANCLE() {
    running=false;
    tool=false;
    show_hide("block","none");
    count2.innerText=`${allarr.length} results`;
}
async function DOWNLOAD(data) {
    try{
        let blob = new Blob([data], {type: 'text/csv'});
        const filee=await window.showSaveFilePicker();
        const fwrite=await filee.createWritable();
        await fwrite.write(blob);
        await fwrite.close();
        show_hide("block","none");
        count2.innerText=`${allarr.length} results`;
        allarr=false;
        tool=false;
        running=false;
    }catch(err){}   
}
function store(message){
    if(!create_tab){temparr=message}
    message.forEach(check => {
        if(allarr.includes(check)==false){
            allarr.push(check)
        }});
    temparr=allarr;    
    count.innerText=`${allarr.length} results are saved`;
}
function DELETE() {
    allarr=[];
    count.innerText=`${allarr.length} results are saved`;
}
function show_hide(one,two) {
    view.document.getElementById("tools").style.display=one;
    view.document.getElementById("operate").style.display=two;
}
function auto(){
    if(running){
        if(tool=="COPY_URL"){
            return COPY_URL()
        }else if(tool=="FILE_URL"){
            return FILE_URL()
        }else if(tool=="SPIDER"){
            return SPIDER()
        }
    }
}

//===================================================================

function popup_called(method,message){ 
    if(method=="call_background"){
        return opening()

    }else if(method=="COPY_URL"){
        show_hide("none","block");
        running=true;tool=method;
        return COPY_URL();

    }else if(method=="FILE_URL"){
        show_hide("none","block");
        tool=method;running=true;
        return FILE_URL();

    }else if(method=="SPIDER"){
        show_hide("none","block");
        tool=method;running=true;
        return SPIDER();

    }else if(method=="CANCLE"){
        return CANCLE()

    }else if(method=="DOWNLOAD"){
        if(allarr.length!=0){return DOWNLOAD(allarr.join(",").replaceAll(",","\n"));}

    }else if(method=="store"){
        return store(message)

    }else if(method=="DELETE"){
        return DELETE()

    }else if(method=="ready"){
        if(!create_tab){url=message; domain=url.match(/https:\/\/[^\/]+/)[0]}
        return auto()
    }

}

//=============================================================

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResonsep) {
        popup_called(request.method,request.message)
    });
