//
//  JUKImporter.m
//  JukeKit
//
//  Created by Thomas Günzel on 14.12.2017.
//  Copyright © 2017 Thomas Günzel. All rights reserved.
//

#import "TagLibImporter.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdocumentation-deprecated-sync"
#pragma GCC diagnostic ignored "-Wdocumentation"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#import <fileref.h>
#import <tag.h>
#import <tpropertymap.h>

#import <rifffile.h>
#import <aifffile.h>
#include <mpegfile.h>

#include <id3v2tag.h>
#include <id3v2frame.h>
#include <id3v2header.h>
#include <attachedpictureframe.h>
#include <textidentificationframe.h>
#include <commentsframe.h>
#include <mp4tag.h>
//#include <tmap.h>


#include <id3v1tag.h>

#include <iostream>

#import <AVFoundation/AVFoundation.h>

#pragma GCC diagnostic pop

inline NSString *TagLibStringToNS(const TagLib::String &tagString) {
    if (tagString == TagLib::ByteVector::null)
        return nil;
    return [NSString stringWithUTF8String:tagString.toCString()];
}

inline const TagLib::String TagLibStringFromNS(NSString *string) {
    if (string == nil)
        return TagLib::ByteVector::null;
    return TagLib::String([string UTF8String], TagLib::String::UTF8);
}

inline NSString *TagLibTextFrameToNS(const TagLib::ID3v2::TextIdentificationFrame *frame) {
    return [NSString stringWithUTF8String:frame->toString().toCString(true)];
}


@interface TagLibImporter() {
    TagLib::ID3v2::AttachedPictureFrame::Type currentPictureType;
}

+ (int) priority:(TagLib::ID3v2::AttachedPictureFrame::Type) type;

@end

@implementation TagLibImporter

-(instancetype)initWithURL:(NSURL * _Nonnull)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

+ (int) priority:(TagLib::ID3v2::AttachedPictureFrame::Type) type {
    switch (type) {
        case TagLib::ID3v2::AttachedPictureFrame::FrontCover:
            return 0;
        case TagLib::ID3v2::AttachedPictureFrame::FileIcon:
            return 1;
        case TagLib::ID3v2::AttachedPictureFrame::OtherFileIcon:
            return 2;
        case TagLib::ID3v2::AttachedPictureFrame::Illustration:
            return 3;
        case TagLib::ID3v2::AttachedPictureFrame::PublisherLogo:
            return 4;
        default:
            return 100;
    }
}

-(BOOL)import:(NSError *__autoreleasing *)error {
	[self parseID3];
	
	return YES;
}

-(void)parseID3 {
	TagLib::FileRef f(_url.fileSystemRepresentation);
    
    if (!f.isNull()) {
        TagLib::Tag *tag = f.tag();
        
        [self setTitle: TagLibStringToNS(tag->title())];
        [self setArtist: TagLibStringToNS(tag->artist())];
        [self setAlbum: TagLibStringToNS(tag->album())];
        [self setGenre: TagLibStringToNS(tag->genre())];
        [self setYear: tag->year()];
        // Comment
        // Tracknumber

        if (TagLib::MPEG::File *file = dynamic_cast<TagLib::MPEG::File *>(f.file())) {
            if (file->hasID3v2Tag()) {
                [self importID3v2:file->ID3v2Tag()];
            }
        }
        else if (TagLib::RIFF::AIFF::File *file = dynamic_cast<TagLib::RIFF::AIFF::File *>(f.file())) {
            if (file->hasID3v2Tag()) {
                [self importID3v2:file->tag()];
            }
        }
    }
}

#pragma mark ID3v2

-(void)importID3v2:(TagLib::ID3v2::Tag *)tag {
    TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
    for(; it != tag->frameList().end(); it++) {
		auto frame = (*it);
		if(auto picture_frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(frame)) {
            if([self image] == nil || ([TagLibImporter priority: picture_frame->type()] < [TagLibImporter priority: currentPictureType])) {
                
                TagLib::ByteVector imgVector = picture_frame->picture();
                NSData *data = [NSData dataWithBytes:imgVector.data() length:imgVector.size()];
                [self setImage: [[NSImage alloc] initWithData: data]];
                currentPictureType = picture_frame->type();
			}
		} else if(auto text_frame = dynamic_cast<TagLib::ID3v2::TextIdentificationFrame *>(frame)) {
            auto frame_id = text_frame->frameID();
            NSString *textString = TagLibTextFrameToNS(text_frame);
            if (frame_id == AVMetadataID3MetadataKeyInitialKey.UTF8String) {
                [self setInitialKey: textString];
            } else if(frame_id == AVMetadataID3MetadataKeyBeatsPerMinute.UTF8String) {
                [self setBpm: textString];
            }
        }
//        } else if(auto comment_frame = dynamic_cast<TagLib::ID3v2::CommentsFrame *>(frame)) {
//            self.track.comment = JUKTagLibCommentFrameToNS(comment_frame);
//        }
		
//        std::cout << frame->frameID() << ": " << frame->toString() << std::endl;
	}
}

-(void)importMP4:(TagLib::MP4::Tag *)tag {
//    const TagLib::MP4::ItemMap &map = tag->itemMap();
//    TagLib::MP4::ItemMap::ConstIterator it = map.begin();
//    for(; it != map.end(); it++) {
//        auto item = (*it);
//        std::cout << item.first << "\t is actually \t " << item.second.toStringList() << std::endl;
//    }
	
}

-(BOOL)write:(NSError *__autoreleasing *)error {
    TagLib::FileRef f(_url.fileSystemRepresentation);
    
    if (!f.isNull()) {
        TagLib::Tag *tag = f.tag();
        
        tag->setTitle(TagLibStringFromNS(_title));
        tag->setArtist(TagLibStringFromNS(_artist));
        tag->setAlbum(TagLibStringFromNS(_album));
        tag->setGenre(TagLibStringFromNS(_genre));
        tag->setYear(_year);

        // TODO Insert an id3 tag if none is there yet
        if (TagLib::MPEG::File *file = dynamic_cast<TagLib::MPEG::File *>(f.file())) {
            if (file->hasID3v2Tag()) {
                [self writeID3v2:file->ID3v2Tag()];
            }
        }
        else if (TagLib::RIFF::AIFF::File *file = dynamic_cast<TagLib::RIFF::AIFF::File *>(f.file())) {
            if (file->hasID3v2Tag()) {
                [self writeID3v2:file->tag()];
            }
        }
        
        if (!f.save()) {
            @throw [NSException exceptionWithName:@"FileWriteException"
                                           reason:@"File could not be saved"
                                         userInfo:nil];
        }
    }
    else {
        @throw [NSException exceptionWithName:@"FileNotFoundException"
                            reason:@"File Not Found on System"
                            userInfo:nil];
    }
    
    return YES;
}

+(void)replaceFrame:(TagLib::ID3v2::Tag *) tag name:(NSString *)name text:(NSString *)text {
    TagLib::String tName = TagLibStringFromNS(name);

    // Remove existing
    tag->removeFrames(name.UTF8String);
    
    // Add new
    if (text != nil) {
        TagLib::String tText = TagLibStringFromNS(text);
        tag->addFrame(TagLib::ID3v2::Frame::createTextualFrame(tName, tText));
    }
}


-(void)writeID3v2:(TagLib::ID3v2::Tag *)tag {
    [TagLibImporter replaceFrame:tag name:AVMetadataID3MetadataKeyInitialKey text:_initialKey];
    [TagLibImporter replaceFrame:tag name:AVMetadataID3MetadataKeyBeatsPerMinute text:_bpm];
}

@end
