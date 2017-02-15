//
//  WebParser.swift
//  WebReader
//
//  Created by Wayne Chang on 2017/2/2.
//  Copyright © 2017年 WayneChang. All rights reserved.
//

import Foundation
import Alamofire
import Kanna

var NonSense: [String] = [
    "(adsbygoogle = window.adsbygoogle || []).push({});", "章节缺失、错误举报", "U","看书","请记住本书首发域名",
    "言情小说网手机版阅读网址：","手机版阅读网址：", "：。"
]
typealias chapterTuple = (text: String?, url: String?)



class Book {
    
    let bookUrl: String
    let domain: String
    var bookTitle: String?
    var bookAuthor: String?
    var updateDate: String?
    
    init(url: String) {
        bookUrl = url
        domain = (NSURL(string: url)?.host)! + "/"
    }
    func printBookInfo() {
        assert(false, "This method must be overriden by the subclass")
    }

    func setBookInfo(completion: @escaping (String) -> Void) {
        assert(false, "This method must be overriden by the subclass")
    }
    

    
}

class UUBook: Book {
    
    override func setBookInfo(completion: @escaping (String) -> Void) {
        Alamofire.request(self.bookUrl).response { response in
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                if let doc = Kanna.HTML(html: utf8Text, encoding: .utf8) {
                    if let bookname = doc.at_css("dl dt"){
                        let isTraditional: Bool! = UserDefaults.standard.bool(forKey: "isTraditional")
                        if(isTraditional == true){
                            self.bookTitle = s2t(text: bookname.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                        }else {
                            self.bookTitle = bookname.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        completion(self.bookTitle!)
                    }
                }
            }
        }
    }

    override func printBookInfo() {
        print("\(self.bookTitle), \(self.bookUrl)")
    }
    
    init(bookUrl: String) {
        super.init(url: bookUrl)
    }
}




func getBookList(url: String) -> Void{
    Alamofire.request(url).response { response in
        //print(url)
        print(response)
        if let data = response.data, let utf8Text = String(data:data, encoding: .utf8) {
            print(utf8Text)
            if let doc = Kanna.HTML(html: utf8Text, encoding: .utf8) {
                for link in doc.xpath("//div[contains(@class, 'gs-title')] // a") {
                    print(link.text!)
                    print(link["href"]!)
                }
                
            }
        }
    }
}


func getBookChapterList(url: String, domain: String, completionHandler: @escaping ([chapterTuple]) -> () ){
    
    var chapterList: [chapterTuple] = []
    var chapterInfo:(String?, String?) = (nil, nil)
    
    Alamofire.request(url).response { response in
        if let data = response.data, let utf8Text = String(data:data, encoding: .utf8) {
            if let doc = Kanna.HTML(html: utf8Text, encoding: .utf8) {
                let isTraditional: Bool! = UserDefaults.standard.bool(forKey: "isTraditional")
                
                if(isTraditional == true){
                    for link in doc.xpath("//div[contains(@class, 'ml-list')] // a") {
                        chapterInfo = (text:s2t(text:link.text!), url:link["href"]!)
                        chapterList.append(chapterInfo)
                    }
                }else {
                    for link in doc.xpath("//div[contains(@class, 'ml-list')] // a") {
                        chapterInfo = (text:link.text!, url:link["href"]!)
                        chapterList.append(chapterInfo)
                    }
                }
                completionHandler(chapterList)
            }
        }
    }
}


func getChapterContent(url: String, domain: String, completionHandler: @escaping (String, String, String?) -> ()){
    
    var contentText: String = ""
    // Ckeck url completeness before concatenation
    let fullUrl = "http://" + domain + url
    var nextUrl: String?
    var chapterTitle: String!
    
    Alamofire.request(fullUrl).response{ response in
        if let data = response.data, var utf8Text = String(data:data, encoding: .utf8){
            // refine content presentation
            utf8Text = utf8Text.replacingOccurrences(of: "<br>", with: "\n")
            utf8Text = utf8Text.replacingOccurrences(of: "<br/>", with: "\n")
            utf8Text = utf8Text.replacingOccurrences(of: "<p>", with: "\n")
            utf8Text = utf8Text.replacingOccurrences(of: "<p/>", with: "\n")
            if let doc = Kanna.HTML(html: utf8Text, encoding: .utf8) {
                
                for txt in doc.xpath("//h3"){
                    chapterTitle = s2t(text:txt.text)
                }
                
                contentText = chapterTitle + "\n"
                
                for content in doc.xpath("//div[contains(@id, 'bookContent')]") {
                    contentText += content.text!
                }
                
                for url in doc.xpath("//div[contains(@class, 'rp-switch')] //a[contains(@id, 'read_next')]") {
                    nextUrl = url["href"]
                }
                
                
                // Compare time with the replacing function inside the above for-loop
                for words in NonSense {
                    if (words == "(adsbygoogle = window.adsbygoogle || []).push({});") {
                        contentText = contentText.replacingOccurrences(of: "\n\n\n", with: "")
                        //contentText = contentText.replacingOccurrences(of: "\n\n", with: "\n")
                    }
                    contentText = contentText.replacingOccurrences(of: words, with: "")
                }
                let isTraditional: Bool! = UserDefaults.standard.bool(forKey: "isTraditional")
                if (isTraditional == true){
                    contentText = s2t(text: contentText)!
                }
                completionHandler(contentText, chapterTitle, nextUrl)
            }
            
        }
    
    }
    
}
