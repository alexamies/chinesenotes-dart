chrome.runtime.onInstalled.addListener(() => {
  console.log('running background script');
  chrome.contextMenus.create({
    "id": "cnotes",
    "title": "Lookup with Chinese Notes ...",
    "contexts": ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener((info) => {
  console.log(`CNotes context menu clicked ${info.selectionText}`);
  chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
    const tabId = tabs[0].id;
    console.log(`sendMessage to tab ${tabId}`)
    chrome.tabs.sendMessage(tabId, {term: info.selectionText});
  });
});
