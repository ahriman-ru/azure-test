#!/usr/bin/env python
#
# A library that provides a Python interface to the Telegram Bot API
# Copyright (C) 2015-2017
# Leandro Toledo de Souza <devs@python-telegram-bot.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].
"""This module contains the classes that represent Telegram
InlineQueryResultAudio"""

from telegram import InlineQueryResult, InlineKeyboardMarkup, InputMessageContent


class InlineQueryResultAudio(InlineQueryResult):
    """
    Represents a link to an mp3 audio file. By default, this audio file will be sent by the user.
    Alternatively, you can use :attr:`input_message_content` to send a message with the specified
    content instead of the audio.

    Attributes:
        type (:obj:`str`): 'audio'.
        id (:obj:`str`): Unique identifier for this result, 1-64 bytes.
        audio_url (:obj:`str`): A valid URL for the audio file.
        title (:obj:`str`): Title.
        performer (:obj:`str`): Optional. Caption, 0-200 characters.
        audio_duration (:obj:`str`): Optional. Performer.
        caption (:obj:`str`): Optional. Audio duration in seconds.
        reply_markup (:class:`telegram.InlineKeyboardMarkup`): Optional. Inline keyboard attached
            to the message.
        input_message_content (:class:`telegram.InputMessageContent`): Optional. Content of the
            message to be sent instead of the audio.

    Args:
        id (:obj:`str`): Unique identifier for this result, 1-64 bytes.
        audio_url (:obj:`str`): A valid URL for the audio file.
        title (:obj:`str`): Title.
        performer (:obj:`str`, optional): Caption, 0-200 characters.
        audio_duration (:obj:`str`, optional): Performer.
        caption (:obj:`str`, optional): Audio duration in seconds.
        reply_markup (:class:`telegram.InlineKeyboardMarkup`, optional): Inline keyboard attached
            to the message.
        input_message_content (:class:`telegram.InputMessageContent`, optional): Content of the
            message to be sent instead of the audio.
        **kwargs (:obj:`dict`): Arbitrary keyword arguments.
    """

    def __init__(self,
                 id,
                 audio_url,
                 title,
                 performer=None,
                 audio_duration=None,
                 caption=None,
                 reply_markup=None,
                 input_message_content=None,
                 **kwargs):

        # Required
        super(InlineQueryResultAudio, self).__init__('audio', id)
        self.audio_url = audio_url
        self.title = title

        # Optionals
        if performer:
            self.performer = performer
        if audio_duration:
            self.audio_duration = audio_duration
        if caption:
            self.caption = caption
        if reply_markup:
            self.reply_markup = reply_markup
        if input_message_content:
            self.input_message_content = input_message_content

    @classmethod
    def de_json(cls, data, bot):
        data = super(InlineQueryResultAudio, cls).de_json(data, bot)

        if not data:
            return None

        data['reply_markup'] = InlineKeyboardMarkup.de_json(data.get('reply_markup'), bot)
        data['input_message_content'] = InputMessageContent.de_json(
            data.get('input_message_content'), bot)

        return cls(**data)
