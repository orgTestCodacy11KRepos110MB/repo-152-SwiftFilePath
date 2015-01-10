//
//  SwiftFilePathTests.swift
//  SwiftFilePathTests
//
//  Created by nori0620 on 2015/01/10.
//  Copyright (c) 2015年 Norihiro Sakamoto. All rights reserved.
//

import XCTest

import SwiftFilePath

// MARK: Extensions as Test utils

extension String {
    
    func match(pattern: String) -> Bool {
        var error : NSError?
        let matcher = NSRegularExpression(pattern: pattern, options: nil, error: &error)
        return matcher?.numberOfMatchesInString(self, options: nil, range: NSMakeRange(0, self.utf16Count)) != 0
    }
    
}


extension Either {
    
    var isSuccess : Bool {
        switch self {
            case .Success(let success):
                return true
            case .Failure(let failure):
                return false
        }
    }
    
    var isFailure: Bool {
        switch self {
            case .Success(let success):
                return false
            case .Failure(let failure):
                return true
        }
    }
    
}


// MARK: Test cases

class SwiftFilePathTests: XCTestCase {
    
    let sandboxDir = Dir.temporaryDir.subdir("sandbox")
    
    override func setUp() {
        super.setUp()
        self.sandboxDir.mkdir()
    }
    
    override func tearDown() {
        super.tearDown()
        self.sandboxDir.remove()
    }
    
    func locally(x: () -> ()) {
        x()
    }
    
    
    // MARK:
    
    #if os(iOS)
    func testDirFactories() {
        
        let homeDir = Dir.homeDir
        XCTAssertTrue(
            homeDir.asString.match("/data")
        )
        
        let temporaryDir = Dir.temporaryDir
        XCTAssertTrue(
            temporaryDir.asString.match("/data/tmp/")
        )
        
        let documentsDir = Dir.documentsDir
        XCTAssertTrue(
            documentsDir.asString.match("/data/Documents")
        )
        
        let cacheDir = Dir.cacheDir
        XCTAssertTrue(
            cacheDir.asString.match("/data/Library/Caches")
        )
        
    }
    #endif
    
    func testDir(){
        let dir = sandboxDir.subdir("bar")
        XCTAssertEqual( dir.basename, "bar")
    }
    
    func testFile() {
        let file = sandboxDir.file("hoge.txt")
        XCTAssertTrue(
            file.path.match("/data/tmp/sandbox/hoge.txt")
        )
        XCTAssertEqual( file.extention, "txt")
        XCTAssertEqual( file.basename, "hoge.txt")
        XCTAssertTrue(
            file.dir.path.match("/data/tmp/sandbox")
        )
        
    }
    
    func testAttributes() {
        
        let file = sandboxDir.file("foo.txt")
        file.touch()
        let attributes = file.attributes
        var permission:Int? = file.attributes.filePosixPermissions()
        XCTAssertEqual( permission!,420);
        
    }
    
    
    // MARK:
    
    func testTouchAndRemove(){
        let file = sandboxDir.file("file.txt")
        
        XCTAssertFalse( file.exists )
       
        locally { // touch
            let result = file.touch()
            XCTAssertTrue( result.isSuccess )
            XCTAssertTrue( file.exists )
        }
        
        locally { // remove
            let result = file.remove()
            XCTAssertTrue( result.isSuccess )
            XCTAssertFalse( file.exists )
        }
        
    }
    
    func testMkdirAndRemove(){
        
        let fruitsDir = sandboxDir.subdir("fruits")
        XCTAssertTrue(
            fruitsDir.path.match("/data/tmp/sandbox/fruits")
        )
        XCTAssertFalse( fruitsDir.exists )
        
        locally { // mkdir
            let result = fruitsDir.mkdir()
            XCTAssertTrue( result.isSuccess )
            XCTAssertTrue( fruitsDir.exists )
        }
        
        locally { // remove
            let result = fruitsDir.remove()
            XCTAssertTrue( result.isSuccess )
            XCTAssertFalse( fruitsDir.exists )
        }
    }
    
    // MARK:
    
    func testDirHierarchy() {
       
        let booksDir  = sandboxDir.subdir("books")
        let comicsDir = booksDir.subdir("comics")
        let comic = comicsDir.file("DragonBall")
        
        XCTAssertFalse( booksDir.exists )
        XCTAssertFalse( comicsDir.exists )
        XCTAssertFalse( comic.exists )
        
        locally { // mkdir
            let result = comicsDir.mkdir()
            XCTAssertTrue( result.isSuccess )
            XCTAssertTrue( booksDir.exists )
            XCTAssertTrue( comicsDir.exists )
        }
        
        locally { // touch
            let result = comic.touch()
            XCTAssertTrue( result.isSuccess )
            XCTAssertTrue( comic.exists )
            
            let relativeComic = self.sandboxDir.file("books/comics/DragonBall")
            XCTAssertTrue( relativeComic.exists )
        }
        
        locally { // remove rootDir
            let result = booksDir.remove()
            XCTAssertTrue( result.isSuccess )
            XCTAssertFalse( booksDir.exists )
            XCTAssertFalse( comicsDir.exists )
            XCTAssertFalse( comic.exists )
        }
        
    }
    
    func testSubDir() {
        let dir = sandboxDir.subdir("foo")
        XCTAssertTrue(
            dir.path.match("/data/tmp/sandbox/foo")
        )
    }
    
    func testParentDir() {
        let dir = sandboxDir.subdir("foo")
        XCTAssertTrue(
            dir.path.match("/data/tmp/sandbox/foo")
        )
        XCTAssertTrue(
            dir.parent.path.match("/data/tmp/sandbox")
        )
        XCTAssertTrue(
            dir.parent.parent.parent.path.match("/data")
        )
        XCTAssertTrue(
            dir.parent.parent.parent.parent.path.match("/")
        )
        XCTAssertTrue(
            dir.parent.parent.parent.parent.parent.parent.path.match("/")
        )
        
    }
    
    // MARK
    
    func testChildren(){
        
        sandboxDir.file("foo.txt").touch()
        sandboxDir.file("bar.txt").touch()
        
        let subdir = sandboxDir.subdir("mydir")
        subdir.mkdir()
        subdir.file("wow.txt").touch()
        subdir.file("wooo.txt").touch()
       
        let boxContents = sandboxDir.contents
        XCTAssertEqual( boxContents.count, 3)
        
        for content in boxContents {
            XCTAssertTrue(content.exists)
        }
        
        let dirsInContents = boxContents.filter({content in
            return content.isDir
        })
        XCTAssertEqual( dirsInContents.count, 1)
        XCTAssertEqual( dirsInContents.first!.path , subdir.path )
        
    }
    
    func testIterator(){
        
        sandboxDir.file("foo.txt").touch()
        sandboxDir.file("bar.txt").touch()
        
        let subdir = sandboxDir.subdir("mydir")
        subdir.mkdir()
       
        var contentCount = 0
        var dirCount     = 0
        
        for content in sandboxDir {
            XCTAssertTrue(content.exists)
            contentCount++
            if( content.isDir ){ dirCount++ }
        }
        XCTAssertEqual( contentCount, 3)
        XCTAssertEqual( dirCount, 1)
       
        
    }
    
    // MARK
    
    func testReadWriteString(){
        
        let textFile = sandboxDir.file("test.txt")
        
        locally {
            let result = textFile.writeString("foo")
            XCTAssertTrue( result.isSuccess )
            let readString = textFile.readString()!
            XCTAssertEqual( readString, "foo")
        }
        
        locally {
            let result = textFile.writeString("bar")
            XCTAssertTrue( result.isSuccess )
            let readString = textFile.readString()!
            XCTAssertEqual( readString, "bar")
        }
        
        locally {
            textFile.remove()
            let readString = textFile.readString() ?? "failed to read"
            XCTAssertEqual( readString, "failed to read")
        }
        
    }
    
    func testReadWriteData(){
        
        let binFile = sandboxDir.file("test.bin")
        
        locally {
            let string  = "HelloData"
            let data    = string.dataUsingEncoding(NSUTF8StringEncoding)
            let result = binFile.writeData( data! )
            XCTAssertTrue( result.isSuccess )
            
            let readData = binFile.readData()
            let readString = NSString(data: readData!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual( readString, "HelloData")
        }
        
        locally {
            let string  = "HelloData Again"
            let data    = string.dataUsingEncoding(NSUTF8StringEncoding)
            let result = binFile.writeData( data! )
            XCTAssertTrue( result.isSuccess )
            
            let readData = binFile.readData()
            let readString = NSString(data: readData!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual( readString, "HelloData Again")
        }
        
        locally {
            binFile.remove()
            let empty = NSData()
            let readData = binFile.readData() ?? empty
            XCTAssertEqual( readData, empty )
        }
    }
}
    