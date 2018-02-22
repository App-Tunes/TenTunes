//
//  JUKImporter.m
//  JukeKit
//
//  Created by Thomas Günzel on 14.12.2017.
//  Copyright © 2017 Thomas Günzel. All rights reserved.
//

#import "JUKImporter.h"

#import <fileref.h>
#import <tag.h>
#import <tpropertymap.h>

#import <rifffile.h>
#import <aifffile.h>

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

inline NSString *JUKTagLibStringToNS(const TagLib::String &tagString) {
	return [NSString stringWithUTF8String:tagString.toCString()];
}

inline NSStringEncoding JUKTagLibEncodingToNS(const TagLib::String::Type type) {
	NSStringEncoding encoding = NSUTF8StringEncoding;
	switch(type) {
		case TagLib::String::Type::Latin1:
			encoding = NSISOLatin1StringEncoding;
			break;
		case TagLib::String::UTF16:
			encoding = NSUTF16StringEncoding;
			break;
		case TagLib::String::UTF16BE:
			encoding = NSUTF16BigEndianStringEncoding;
			break;
		case TagLib::String::UTF8:
			encoding = NSUTF8StringEncoding;
			break;
		case TagLib::String::UTF16LE:
			encoding = NSUTF16LittleEndianStringEncoding;
			break;
	}
	return encoding;
}

inline NSString *JUKTagLibTextFrameToNS(const TagLib::ID3v2::TextIdentificationFrame *frame) {
	NSStringEncoding encoding = JUKTagLibEncodingToNS(frame->textEncoding());
	return [NSString stringWithCString:frame->toString().toCString() encoding:encoding];
}

inline NSString *JUKTagLibCommentFrameToNS(const TagLib::ID3v2::CommentsFrame *frame) {
	NSStringEncoding encoding = JUKTagLibEncodingToNS(frame->textEncoding());
	return [NSString stringWithCString:frame->text().toCString() encoding:encoding];
}

@interface JUKImporter()


@end

@implementation JUKImporter

-(instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

-(BOOL)import:(NSError *__autoreleasing *)error {
	[self parseID3];
	[self loadDuration];
	
	return YES;
}

-(void)parseID3 {
	TagLib::FileRef f(_url.fileSystemRepresentation);
	
	if(TagLib::ID3v2::Tag *tag = dynamic_cast<TagLib::ID3v2::Tag *>(f.tag())) {
		[self importID3v2:tag];
	} else if(TagLib::ID3v1::Tag *tag = dynamic_cast<TagLib::ID3v1::Tag *>(f.tag())) {
//        std::cout << tag->artist() << std::endl;
	} else if(TagLib::MP4::Tag *tag = dynamic_cast<TagLib::MP4::Tag *>(f.tag())) {
		[self importMP4:tag];
	}
}

-(void)loadDuration {
	AVAsset *asset = [AVAsset assetWithURL:self.url];
	if(asset == nil) {
		NSLog(@"Error reading file!");
		return;
	}
	double duration = CMTimeGetSeconds(asset.duration);
//    self.track.duration = duration;
}

-(void)setTrackArtists:(NSString*)artists {
	NSArray<NSString*> *split = [artists componentsSeparatedByString:@","];
	for (NSString *component in split) {
		[self addTrackArtist:component];
	}
}

-(void)addTrackArtist:(NSString*)artistName {
//    NSString *sanitizedArtist = [artistName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    JUKArtist *artist = [JUKArtist artistNamed:sanitizedArtist inRealm:self.manager.realm createIfNeeded:YES];
//    [self.track.artists addObject:artist];
}

-(void)setTrackAlbum:(NSString*)albumName {
//    NSString *sanitizedAlbum = [albumName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    JUKAlbum *album = [JUKAlbum albumNamed:sanitizedAlbum inRealm:self.manager.realm createIfNeeded:YES];
//    self.track.album = album;
}

-(void)setTrackGenre:(NSString*)genreName {
//    NSString *sanitizedGenre = [genreName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    JUKGenre *genre = [JUKGenre genreNamed:sanitizedGenre inRealm:self.manager.realm createIfNeeded:YES];
//    [self.track.genres addObject:genre];
}

-(void)setTrackYearReleased:(NSString*)releaseDate overwrite:(BOOL)overwrite {
	if(releaseDate.length > 4) {
		releaseDate = [releaseDate substringToIndex:4];
	}
//    if(self.track.yearReleased == nil || overwrite) {
//        self.track.yearReleased = releaseDate;
//    }
}

#pragma mark ID3v2

-(void)importID3v2:(TagLib::ID3v2::Tag *)tag {
	// iterate over frame list
	TagLib::ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
	for(; it != tag->frameList().end(); it++) {
		auto frame = (*it);
		if(auto picture_frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(frame)) {
			if(picture_frame->type() == TagLib::ID3v2::AttachedPictureFrame::Type::FrontCover) {
                TagLib::ByteVector imgVector = picture_frame->picture();
                NSData *data = [NSData dataWithBytes:imgVector.data() length:imgVector.size()];
                [self setImage: [[NSImage alloc] initWithData: data]];
			}
		} else if(auto text_frame = dynamic_cast<TagLib::ID3v2::TextIdentificationFrame *>(frame)) {
            auto frame_id = text_frame->frameID();
            NSString *textString = JUKTagLibTextFrameToNS(text_frame);
//            if(frame_id == AVMetadataID3MetadataKeyTitleDescription.UTF8String) {
//                self.track.name = textString;
//            } else if(frame_id == AVMetadataID3MetadataKeyLeadPerformer.UTF8String) {
//                [self setTrackArtists:textString];
//            } else if(frame_id == AVMetadataID3MetadataKeyAlbumTitle.UTF8String) {
//                [self setTrackAlbum:textString];
//            } else if(frame_id == AVMetadataID3MetadataKeyRecordingTime.UTF8String) {
//                [self setTrackYearReleased:textString overwrite:NO];
//            } else if(frame_id == AVMetadataID3MetadataKeyReleaseTime.UTF8String) {
//                [self setTrackYearReleased:textString overwrite:NO];
//            } else if (frame_id == AVMetadataID3MetadataKeyOriginalReleaseTime.UTF8String) {
//                [self setTrackYearReleased:textString overwrite:NO];
//            } else if (frame_id == AVMetadataID3MetadataKeyOriginalReleaseYear.UTF8String) {
//                [self setTrackYearReleased:textString overwrite:YES];
//            } else if(frame_id == AVMetadataID3MetadataKeyTrackNumber.UTF8String) {
//                self.track.position = textString;
//            }
            if(frame_id == AVMetadataID3MetadataKeyInitialKey.UTF8String) {
                [self setInitialKey: textString];
            } else if(frame_id == AVMetadataID3MetadataKeyBeatsPerMinute.UTF8String) {
                [self setBpm: textString];
            }
//            } else if(frame_id == AVMetadataID3MetadataKeyContentType.UTF8String) {
//                [self setTrackGenre:textString];
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

@end
