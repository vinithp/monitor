function smessage(method,message){
    chrome.runtime.sendMessage({method:method,message:message});
}
//========================================================

let arr=[];

function get_link() {
    const srcNodeList = document.querySelectorAll('[src],[href]');
    let item,value;
    for (let i = 0; i < srcNodeList.length; ++i) {
    item = srcNodeList[i];
    value = item.getAttribute('src');
        if(value !== null){
            if(arr.includes(item.getAttribute('src'))==false){
                arr.push(value);
            }
        }
        else if(value == null){
            if(arr.includes(item.getAttribute('href'))==false){
                arr.push(item.getAttribute('href'));
            }
        }    
    }
    console.log("get_link")
}

//========================================================

function copy_url(){
    arr=[];
    get_link();
    smessage("store",arr);
}
function page_url() {
    arr=[];
    get_link();
    smessage("store",arr); 
}
function spider(){
    arr=[];
    get_link();
    smessage("store",arr);
    console.log("store")

}

//========================================================

function popup_called(tool){
    if(tool=="COPY_URL"){ 
        copy_url()
    }
    else if(tool=="FILE_URL"){
        page_url()
        try{
            window.close()
        }catch(err){return}
    }
    else if(tool=="SPIDER"){
        spider()
        try{
            window.close()
        }catch(err){return}
    }
}

//=====================================================

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        popup_called(request.tool); 
        sendResponse(true);
    }
  );

//====================================================

window.addEventListener('load',function () {
    smessage("ready","https://"+window.location.hostname+window.location.pathname)
})


